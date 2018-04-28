defmodule Borscht do
  @moduledoc """
  Documentation for Borscht.
  """

  use Application

  alias Borscht.{Backtrace, Notice, Reporter}

  @reporters_registy_name :borscht_reporters

  def start(_type, _options) do
    # {:ok, config} = Borscht.Config.read()

    opts = [strategy: :rest_for_one, name: __MODULE__]

    children = [{Registry, [keys: :unique, name: @reporters_registy_name]}]

    result = Supervisor.start_link(children, opts)
    {:ok, _} = result

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

  defp notify_reporters(notice) do
    [{_, reporters}] = Registry.lookup(@reporters_registy_name, "reporters")
    reporters |> Enum.each(&Reporter.report(&1, notice))
  end
end
