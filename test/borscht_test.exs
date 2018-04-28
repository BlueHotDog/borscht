defmodule BorschtTest do
  use Borscht.Case
  doctest Borscht

  require Logger

  # setup do
  #   restart_with_config([app: :test_app, exclude_envs: []], self())
  # end

  # test "logging a crash" do
  #   :proc_lib.spawn(fn ->
  #     raise RuntimeError, "Oops"
  #   end)

  #   assert_receive {:report, %Borscht.Notice{} = notice}

  #   assert %Borscht.Notice{error: %{class: "RuntimeError"}} = notice
  #   assert %Borscht.Notice{request: %{context: nil}} = notice

  #   assert %Borscht.Notice{
  #            server: %{
  #              environment_name: :test,
  #              hostname: hostname,
  #              project_root: project_root
  #            }
  #          } = notice

  #   assert is_bitstring(hostname)
  #   assert is_bitstring(project_root)
  # end

  test "sending a notice on an active environment" do
    restart_with_config([exclude_envs: [], app: "something"], self())

    :ok = Borscht.notify(%RuntimeError{})
    assert_receive {:report, _notice}
  end

  # test "fail to start if missing config param" do
  #   {:error, {:borscht, {:bad_return, {_, exit_reason}}}} =
  #     restart_with_config(app: nil, environment_name: :test, exclude_envs: [])

  #   assert {:EXIT, {%Elixir.Borscht.Config.MissingConfigParams{}, _}} = exit_reason
  # end

  # test "sending a notice on an inactive environment doesn't report" do
  #   restart_with_config(exclude_envs: [:test])
  #   :ok = Borscht.notify(%RuntimeError{})
  #   refute_received {:report, _notice}
  # end

  # test "sending a notice with exception stacktrace" do
  #   restart_with_config(exclude_envs: [])

  #   try do
  #     raise RuntimeError
  #   rescue
  #     exception ->
  #       :ok = Borscht.notify(exception)
  #   end

  #   assert_received {:report, %Borscht.Notice{error: %{backtrace: backtrace}}}

  #   traced = for %{file: file, method: fun} <- backtrace, do: {file, fun}

  #   refute {"lib/process.ex", "info/1"} in traced
  #   refute {"lib/borscht.ex", "backtrace/1"} in traced
  #   refute {"lib/borscht.ex", "notify/3"} in traced

  #   assert {"test/borscht_test.exs", "test sending a notice with exception stacktrace/1"} in traced
  # end
end
