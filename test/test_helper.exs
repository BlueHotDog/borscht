Logger.remove_backend(:console)

ExUnit.start(assert_receive_timeout: 1000, refute_receive_timeout: 1000)

defmodule Borscht.Case do
  use ExUnit.CaseTemplate
  @app_name :borscht

  using _ do
    quote do
      import unquote(__MODULE__)
    end
  end

  def restart_with_config(opts, pid) do
    default_options = [
      reporters: [%{reporter: Borscht.TestReporter, opts: %{test_pid: pid}}]
    ]

    opts = Keyword.merge(default_options, opts)

    :ok =
      case Application.stop(@app_name) do
        {:error, {:not_started, @app_name}} -> :ok
        :ok -> :ok
        other -> other
      end

    original = take_original_env(opts)

    put_all_env(opts)

    on_exit(fn ->
      put_all_env(original)
    end)

    case Application.ensure_all_started(@app_name) do
      {:ok, _} -> :ok
      {:error, error} -> {:error, error}
    end
  end

  defp take_original_env(opts) do
    Keyword.take(Application.get_all_env(@app_name), Keyword.keys(opts))
  end

  defp put_all_env(opts) do
    Enum.each(opts, fn {key, val} ->
      Application.put_env(@app_name, key, val)
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

  def handle_call({:report, notice}, _from, %{test_pid: pid} = state) do
    Apex.ap(pid)
    send(pid, {:report, notice})
    {:reply, {:ok, nil}, state}
  end
end
