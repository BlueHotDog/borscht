defmodule Borscht do
  @moduledoc """
  Documentation for Borscht.
  """

  use Application

  alias Borscht.{Backtrace, Client, Notice}

  def start(_type, _options) do
    {:ok, config} = Borscht.Config.read()

    if config[:enabled] do
      :error_logger.add_report_handler(Borscht.Logger)
    end

    Apex.ap(config)

    children = [
      # worker(Client, [config])
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end

  @spec notify(Notice.noticeable(), map, list) :: :ok
  def notify(exception, metadata \\ %{}, stacktrace \\ nil) do
    exception |> Notice.new(contextual_metadata(metadata), backtrace(stacktrace))

    :ok
    # |> Reporter.send_notice()
  end

  defp contextual_metadata(%{context: _} = metadata) do
    metadata
  end

  defp contextual_metadata(metadata) do
    %{context: metadata}
  end

  defp backtrace(nil) do
    backtrace(System.stacktrace())
  end

  defp backtrace([]) do
    {:current_stacktrace, stacktrace} = Process.info(self(), :current_stacktrace)

    backtrace(stacktrace)
  end

  defp backtrace(stacktrace) do
    Backtrace.from_stacktrace(stacktrace)
  end
end
