defmodule Borscht do
  @moduledoc """
  Documentation for Borscht.
  """

  use Application

  alias Borscht.{Backtrace, Notice}

  @reporters_registy_name :borscht_reporters

  def start(_type, _options) do
    {:ok, config} = Borscht.Config.read()

    if enabled?(config) do
      :error_logger.add_report_handler(Borscht.Logger)
    end

    opts = [strategy: :rest_for_one, name: __MODULE__]

    enabled_reporters = Borscht.Config.enabled_reporters(config)

    children = for reporter <- enabled_reporters, into: [], do: create_worker(config, reporter)

    children = children ++ [{Registry, [keys: :unique, name: @reporters_registy_name]}]
    result = Supervisor.start_link(children, opts)
    register_reporters(enabled_reporters)
    result
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

  defp enabled?(config) do
    config[:enabled] == true || is_nil(config[:enabled])
  end

  defp notify_reporters(notice) do
    [{_, reporters}] = Registry.lookup(@reporters_registy_name, "reporters")
    reporters |> Enum.each(&Borscht.Reporter.report(&1, notice))
  end

  defp register_reporters(reporters) when is_list(reporters) do
    {:ok, _} = Registry.register(@reporters_registy_name, "reporters", reporters)
  end

  defp create_worker(config, %{reporter: reporter, args: args})
       when is_atom(reporter) do
    args_with_config = args |> Map.put_new(:config, config)
    {reporter, [args_with_config]}
  end

  defp create_worker(config, reporter) when is_atom(reporter) do
    {reporter, [%{config: config}]}
  end
end
