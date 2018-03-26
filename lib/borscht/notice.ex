defmodule Borscht.Notice do
  @moduledoc """
  A `Borscht.Notice` struct is used to bundle an exception with system
  information.
  """

  alias __MODULE__
  alias Borscht.Utils

  @typep error :: %{class: atom | iodata, message: iodata, tags: list, backtrace: list}

  @type noticeable :: Exception.t() | map | String.t() | atom

  @typep server :: %{environment_name: atom, hostname: String.t(), project_root: Path.t()}

  @type t :: %__MODULE__{
          server: server,
          error: error,
          request: map
        }

  @enforce_keys [:server, :error, :request]

  defstruct [:server, :error, :request]

  @doc """
  Create a new `Borscht.Notice` struct for various error types.

  ## Example

      iex> Borscht.Notice.new("oops", %{}, []).error
      %{backtrace: [], class: "RuntimeError", message: "oops", tags: []}

      iex> Borscht.Notice.new(:badarg, %{}, []).error
      %{backtrace: [], class: "ArgumentError", message: "argument error", tags: []}

      iex> Borscht.Notice.new(%RuntimeError{message: "oops"}, %{}, []).error
      %{backtrace: [], class: "RuntimeError", message: "oops", tags: []}
  """
  @spec new(noticeable, map, list) :: t
  def new(error, metadata, backtrace)

  def new(message, metadata, backtrace) when is_binary(message) do
    new(%RuntimeError{message: message}, metadata, backtrace)
  end

  def new(%{class: class, message: message}, metadata, backtrace) do
    %{class: class, message: message, backtrace: backtrace}
    |> create(metadata)
  end

  def new(exception, metadata, backtrace) do
    exception = Exception.normalize(:error, exception)

    %{__struct__: exception_mod} = exception

    error = %{
      class: Utils.module_to_string(exception_mod),
      message: exception_mod.message(exception),
      backtrace: backtrace
    }

    create(error, metadata)
  end

  defp create(error, metadata) do
    error = Map.put(error, :tags, Map.get(metadata, :tags, []))
    context = Map.get(metadata, :context, %{})

    request =
      metadata
      |> Map.get(:plug_env, %{})
      |> Map.put(:context, context)

    %Notice{error: error, request: request, server: server()}
  end

  defp server do
    {:ok, env_name} = Borscht.Config.get_env(:environment_name)
    {:ok, hostname} = Borscht.Config.get_env(:hostname)
    {:ok, project_root} = Borscht.Config.get_env(:project_root)

    %{
      environment_name: env_name,
      hostname: hostname,
      project_root: project_root
    }
  end
end
