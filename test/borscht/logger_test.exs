defmodule Borscht.LoggerTest do
  use Borscht.Case

  require Logger

  defmodule Reporter do
    use Borscht.Reporter

    def start_link(opts) do
      GenServer.start_link(__MODULE__, :ok, opts)
    end

    def report(notice) do
      Apex.ap("aaaaaaaaaa")
      # send(test, {:something})
    end

    def init(args) do
      {:ok, args}
    end

    def handle_call({:report, report}, _from, state) do
      Apex.ap("aaaa")
      {:reply, {:ok, nil}, state}
    end
  end

  defmodule ErrorServer do
    use GenServer

    def start do
      GenServer.start(__MODULE__, [])
    end

    def init(_), do: {:ok, []}

    def handle_cast(:fail, _state) do
      raise RuntimeError, "Crashing"
    end
  end

  setup do
    # {:ok, _} = Honeybadger.API.start(self())

    restart_with_config(reporters: [Reporter])

    # on_exit(&Honeybadger.API.stop/0)
  end

  test "logging a crash" do
    :proc_lib.spawn(fn ->
      Borscht.context(user_id: 1)
      raise RuntimeError, "Oops"
    end)

    assert_receive {:api_request, notification}

    assert %{"error" => %{"class" => "RuntimeError"}} = notification
    assert %{"request" => %{"context" => %{"user_id" => 1}}} = notification
  end

  # test "crashes do not cause recursive logging" do
  #   error_report = [
  #     [
  #       error_info: {:error, %RuntimeError{message: "Oops"}, []},
  #       dictionary: [honeybadger_context: [user_id: 1]]
  #     ],
  #     []
  #   ]

  #   log =
  #     capture_log(fn ->
  #       :error_logger.error_report(error_report)
  #     end)

  #   assert log =~ "Unable to notify Honeybadger! BadMapError: "

  #   refute_receive {:api_request, _}
  # end

  # test "log levels lower than :error_report are ignored" do
  #   message_types = [:info_msg, :info_report, :warning_msg, :error_msg]

  #   Enum.each(message_types, fn type ->
  #     apply(:error_logger, type, ["Ignore me"])

  #     refute_receive {:api_request, _}
  #   end)
  # end

  # test "logging exceptions from Tasks" do
  #   Task.start(fn ->
  #     Float.parse("12.345e308")
  #   end)

  #   assert_receive {:api_request, %{"error" => %{"class" => "ArgumentError"}}}
  # end

  # test "logging exceptions from GenServers" do
  #   {:ok, pid} = ErrorServer.start()

  #   GenServer.cast(pid, :fail)

  #   assert_receive {:api_request, %{"error" => %{"class" => "RuntimeError"}}}
  # end
end
