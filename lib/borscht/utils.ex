defmodule Borscht.Utils do
  @moduledoc """
  Assorted helper functions used through out the Borscht package.
  """

  @doc """
  Internally all modules are prefixed with Elixir. This function removes the
  `Elixir` prefix from the module when it is converted to a string.
  # Example
      iex> Borscht.Utils.module_to_string(Borscht.Utils)
      "Borscht.Utils"
  """
  def module_to_string(module) do
    module
    |> Module.split()
    |> Enum.join(".")
  end
end
