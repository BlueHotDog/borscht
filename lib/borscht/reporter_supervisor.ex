defmodule Borscht.ReporterSupervisor do
  use Supervisor

  def start_link(reporters: reporters) do
    Supervisor.start_link(__MODULE__, %{reporters: reporters}, name: __MODULE__)
  end

  def init(%{reporters: reporters}) do
    children = for reporter <- reporters, into: [], do: {reporter, []}
    Supervisor.init(children, strategy: :one_for_one)
  end
end
