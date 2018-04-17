defmodule Borscht do
  @moduledoc """
  Documentation for Borscht.
  """

  use Application

  alias Borscht.{Backtrace, Notice, Reporter}

  @reporters_registy_name :borscht_reporters

  def start(_type, _options) do
    config =
      case Borscht.Config.read() do
        {:ok, config} -> config
        {:error, %Borscht.Config.MissingConfigParams{} = error} -> raise error
      end

    if Borscht.Config.enabled?(config) do
      :error_logger.add_report_handler(Borscht.Logger)
    end

    opts = [strategy: :rest_for_one, name: __MODULE__]

    enabled_reporters =
      Borscht.Config.enabled_reporters(config) |> Enum.map(&Reporter.from_config(&1))

    children =
      for reporter <- enabled_reporters, into: [], do: build_reporter_worker(config, reporter)

    children = [{Registry, [keys: :unique, name: @reporters_registy_name]}] ++ children

    result = Supervisor.start_link(children, opts)
    {:ok, _} = result

    register_reporters(enabled_reporters)

    result
  end

  @doc false
  def stop(_state) do
    :error_logger.delete_report_handler(Borscht.Logger)

    :ok
  end

  @spec notify(Notice.noticeable(), map, list | nil) :: :ok | {:error, term}
  def notify(exception, metadata \\ %{}, stacktrace \\ nil) do
    exception
    |> Notice.new(contextual_metadata(metadata), backtrace(stacktrace))
    |> notify_reporters
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

  defp notify_reporters(notice) do
    [{_, reporters}] = Registry.lookup(@reporters_registy_name, "reporters")
    reporters |> Enum.each(&Reporter.report(&1, notice))
  end

  defp register_reporters(reporters) when is_list(reporters) do
    {:ok, _} = Registry.register(@reporters_registy_name, "reporters", reporters)
  end

  defp build_reporter_worker(config, %Reporter{} = reporter) do
    opts_with_config = reporter.opts |> Map.put_new(:config, config)
    {reporter.reporter, opts_with_config}
  end
end
