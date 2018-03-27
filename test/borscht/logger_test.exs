defmodule Borscht.LoggerTest do
  use Borscht.Case

  require Logger

  defmodule Reporter do
    use Borscht.Reporter

    def start_link(%{config: config} = opts) do
      GenServer.start_link(__MODULE__, opts, name: __MODULE__)
    end

    def report(notice) do
      GenServer.call(__MODULE__, {:report, notice})
    end

    def init(opts) do
      {:ok, opts}
    end

    def handle_call({:report, report}, _from, state) do
      Apex.ap(state)
      {:reply, {:ok, nil}, state}
    end
  end

  setup do
    restart_with_config(reporters: [%{reporter: Reporter, args: %{test: self()}}])
  end

  test "logging a crash" do
    :proc_lib.spawn(fn ->
      raise RuntimeError, "Oops"
    end)

    assert_receive {:api_request, notification}

    assert %{"error" => %{"class" => "RuntimeError"}} = notification
    assert %{"request" => %{"context" => %{"user_id" => 1}}} = notification
  end
end
