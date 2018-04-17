defmodule Borscht.Config do
  @moduledoc """
  Handles all aspects of reading/writing configuration params.
  """
  defmodule MissingConfigParams do
    defexception [:message]

    def exception(params) do
      msg = """
      Missing configuration params: #{inspect(params)}
      """

      %MissingConfigParams{message: msg}
    end
  end

  @type config :: [config_item]
  @type config_item :: {atom, any}

  @spec read() :: {:ok, config} | {:error, term()}
  def read() do
    get_all_env()
    |> merge_with_defaults()
    |> put_dynamic_env()
    |> verify()
    |> persist_all_env()
  end

  @doc """
  Fetch all configuration specific to the :borscht application.
  This resolves values the same way that `get_env/1` does, so it resolves
  :system tuple variables correctly.
  ## Example
      Borscht.get_all_env()
      #=> [environment_name: "dev", reporters: [...]]
  """
  @spec get_all_env() :: config
  def get_all_env do
    for {key, _value} <- Application.get_all_env(:borscht) do
      {:ok, val} = get_env(key)
      {key, val}
    end
  end

  @spec merge_with_defaults(config) :: config
  def merge_with_defaults(config) do
    default = [
      enabled: true,
      exclude_envs: []
    ]

    Keyword.merge(default, config)
  end

  @doc """
  Fetch configuration specific to the :borscht application.
  ## Example
      Borscht.Config.get_env(:exclude_envs)
      #=> [:dev, :test]
  """
  @spec get_env(atom) :: {:ok | :error, any}
  def get_env(key) when is_atom(key) do
    case Application.fetch_env(:borscht, key) do
      {:ok, {:system, var}} when is_binary(var) ->
        {:ok, System.get_env(var)}

      {:ok, value} ->
        {:ok, value}

      :error ->
        {:error, "Configuration parameter #{inspect(key)} is not set"}
    end
  end

  @spec enabled?(config) :: boolean
  def enabled?(config) do
    globally_enabled = config[:enabled] == true
    env_enabled = config[:exclude_envs] |> Enum.find(&(&1 == config[:environment_name])) == nil
    globally_enabled && env_enabled
  end

  def enabled_reporters(config) do
    if enabled?(config) do
      config[:reporters]
    else
      []
    end
  end

  @spec put_dynamic_env(config) :: config
  defp put_dynamic_env(config) do
    hostname = fn ->
      :inet.gethostname()
      |> elem(1)
      |> List.to_string()
    end

    config
    |> Keyword.put_new_lazy(:hostname, hostname)
    |> Keyword.put_new_lazy(:project_root, &System.cwd/0)
  end

  defp verify(config, params \\ [:app]) do
    invalid_params =
      params
      |> Enum.map(&{&1, Keyword.get(config, &1)})
      |> Enum.filter(&(elem(&1, 1) == nil))

    case length(invalid_params) do
      x when x == 0 -> {:ok, config}
      x when x > 0 -> {:error, MissingConfigParams.exception(invalid_params)}
    end
  end

  defp persist_all_env({:ok, config}) do
    Enum.each(config, fn {key, value} ->
      Application.put_env(:borscht, key, value)
    end)

    {:ok, config}
  end

  defp persist_all_env(other), do: other
end
