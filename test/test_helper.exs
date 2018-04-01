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
    :ok =
      case Application.stop(:borscht) do
        {:error, {:not_started, :borscht}} -> :ok
        :ok -> :ok
        other -> other
      end

    original = take_original_env(opts)

    put_all_env(opts)

    on_exit(fn ->
      put_all_env(original)
    end)

    Application.ensure_all_started(:borscht)
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

defmodule Borscht.TestReporter do
  use Borscht.Reporter

  def start_link(%{config: _config, test: _test} = opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def report(notice) do
    GenServer.call(__MODULE__, {:report, notice})
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call({:report, notice}, _from, %{test: test} = state) do
    send(test, {:report, notice})
    {:reply, {:ok, nil}, state}
  end
end
