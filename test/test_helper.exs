Logger.remove_backend(:console)

ExUnit.start(assert_receive_timeout: 1000, refute_receive_timeout: 1000)

defmodule Borscht.Case do
  use ExUnit.CaseTemplate

  using _ do
    quote do
      import unquote(__MODULE__)
    end
  end

  def with_config(opts, fun) when is_function(fun) do
    original = take_original_env(opts)

    try do
      put_all_env(opts)

      fun.()
    after
      put_all_env(original)
    end
  end

  def restart_with_config(opts) do
    :ok = Application.stop(:borscht)
    original = take_original_env(opts)

    put_all_env(opts)

    on_exit(fn ->
      put_all_env(original)
    end)

    :ok = Application.ensure_started(:borscht)
  end

  def capture_log(fun) do
    Logger.add_backend(:console, flush: true)

    on_exit(fn ->
      Logger.remove_backend(:console)
    end)

    ExUnit.CaptureIO.capture_io(:user, fn ->
      fun.()
      :timer.sleep(100)
      Logger.flush()
    end)
  end

  defp take_original_env(opts) do
    Keyword.take(Application.get_all_env(:borscht), Keyword.keys(opts))
  end

  defp put_all_env(opts) do
    Enum.each(opts, fn {key, val} ->
      Application.put_env(:borscht, key, val)
    end)
  end
end
