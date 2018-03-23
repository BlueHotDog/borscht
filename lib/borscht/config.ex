defmodule Borscht.Config do
  defmodule MissingEnvironmentNameError do
    defexception message: """
                 The environment_name setting is required so that we can report the correct
                 environment name. Please configure environment_name in your
                 config.exs and environment specific config files to have accurate reporting
                 of errors.
                 config :borscht, :environment_name, :dev
                 """
  end

  @type config :: [config_item]
  @type config_item :: {atom, any}

  @spec read() :: {:ok, config}
  def read() do
    get_all_env()
    |> put_dynamic_env()
    |> verify_environment_name!()
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
        value

      :error ->
        {:error, "the configuration parameter #{inspect(key)} is not set"}
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

  defp verify_environment_name!(config) do
    case Keyword.get(config, :environment_name) do
      nil -> {:error, MissingEnvironmentNameError}
      _ -> {:ok, config}
    end
  end

  defp persist_all_env({:ok, config}) do
    Enum.each(config, fn {key, value} ->
      Application.put_env(:borscht, key, value)
    end)

    {:ok, config}
  end
end
