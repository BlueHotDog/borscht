defmodule BorschtTest do
  use Borscht.Case
  doctest Borscht

  require Logger

  setup do
    restart_with_config(
      app: "some app",
      reporters: [%{reporter: Borscht.TestReporter, opts: %{test: self()}}]
    )
  end

  test "logging a crash" do
    :proc_lib.spawn(fn ->
      raise RuntimeError, "Oops"
    end)

    assert_receive {:report, notice}

    assert %Borscht.Notice{error: %{class: "RuntimeError"}} = notice
    assert %Borscht.Notice{request: %{context: nil}} = notice

    assert %Borscht.Notice{
             server: %{
               environment_name: :test,
               hostname: hostname,
               project_root: project_root
             }
           } = notice

    assert is_bitstring(hostname)
    assert is_bitstring(project_root)
  end

  test "sending a notice on an active environment" do
    restart_with_config(exclude_envs: [], app: "something")

    :ok = Borscht.notify(%RuntimeError{})
    assert_receive {:report, _notice}
  end

  test "warn if incomplete env" do
    try do
      restart_with_config(app: nil, environment_name: :test, exclude_envs: [])
    rescue
      ex -> Apex.ap(ex)
    end

    # assert logged =~ ~s|mandatory :borscht config key app not set|
  end
end
