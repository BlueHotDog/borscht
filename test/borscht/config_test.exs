defmodule Borscht.ConfigTest do
  use Borscht.Case
  doctest Borscht.Config

  require Logger

  setup do
    restart_with_config(
      app: :test_app,
      exclude_envs: [],
      reporters: [%{reporter: Borscht.TestReporter, opts: %{test: self()}}]
    )
  end

  test "fetching all application values" do
    on_exit(fn ->
      Application.delete_env(:borscht, :option_a)
      Application.delete_env(:borscht, :option_b)
      System.delete_env("OPTION_A")
    end)

    Application.put_env(:borscht, :option_a, {:system, "OPTION_A"})
    Application.put_env(:borscht, :option_b, :value)
    System.put_env("OPTION_A", "VALUE")

    all_env = Borscht.Config.get_all_env()

    assert all_env[:option_a] == "VALUE"
    assert all_env[:option_b] == :value
  end

  test "fetching application values" do
    on_exit(fn ->
      Application.delete_env(:borscht, :unused)
    end)

    Application.put_env(:borscht, :unused, "VALUE")

    assert Borscht.Config.get_env(:unused) == {:ok, "VALUE"}
  end

  test "fetching system values" do
    on_exit(fn ->
      Application.delete_env(:borscht, :unused)
      System.delete_env("UNUSED")
    end)

    Application.put_env(:borscht, :unused, {:system, "UNUSED"})
    System.put_env("UNUSED", "VALUE")

    assert Borscht.Config.get_env(:unused) == {:ok, "VALUE"}
  end

  test "an error returned for unknown config key" do
    assert Borscht.Config.get_env(:unused) ==
             {:error, "Configuration parameter :unused is not set"}
  end
end
