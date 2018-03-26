defmodule Borscht do
  @moduledoc """
  Documentation for Borscht.
  """

  use Application

  alias Borscht.{Backtrace, Notice}

  def start(_type, _options) do
    import Supervisor.Spec, warn: false

    {:ok, config} = Borscht.Config.read()

    if enabled?(config) do
      :error_logger.add_report_handler(Borscht.Logger)
    end

    opts = [strategy: :rest_for_one, name: __MODULE__]

    enabled_reporters = config[:enabled_reporters]
    children = for reporter <- enabled_reporters, into: [], do: worker(reporter, [config])

    Supervisor.start_link(children, opts)
  end

  @spec notify(Notice.noticeable(), map, list | nil) :: :ok | {:error, term}
  def notify(exception, metadata \\ %{}, stacktrace \\ nil) do
    exception
    |> Notice.new(contextual_metadata(metadata), backtrace(stacktrace))
    |> Reporter.send_notice()
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

  defp enabled?(config) do
    config[:enabled] == true || is_nil(config[:enabled])
  end
end
