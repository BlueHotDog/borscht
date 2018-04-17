defmodule Borscht.Backtrace do
  @moduledoc """
  The Backtrace module contains functions for formatting system stacktraces.
  """

  @type stack_item() :: %{
          module: module(),
          function: atom(),
          arity: arity(),
          args: [term],
          location: [location]
        }
  @typep location :: %{filename: String.t(), line: pos_integer()}
  @inspect_opts charlists: :as_lists,
                limit: 5,
                printable_limit: 1024,
                pretty: false

  @doc """
  Convert a system stacktrace into an API compatible backtrace.

  When `filter_args` is disabled the arguments will be included. Arguments are
  inspected and reported as binaries, regardless of the original format.

      iex> stack_item = {:erlang, :funky, [{:ok, 123}], []}
      ...> Borscht.Backtrace.from_stacktrace([stack_item])
      [%{file: nil, number: nil, method: "funky/1", args: ["{:ok, 123}"], context: "all"}]
  """
  @spec from_stacktrace(list(stack_item)) :: list(map)
  def from_stacktrace(stacktrace) when is_list(stacktrace) do
    Enum.map(stacktrace, &format_line/1)
  end

  defp format_line({mod, fun, args, []}) do
    format_line({mod, fun, args, [file: nil, line: nil]})
  end

  defp format_line({mod, fun, args, [file: file, line: line]}) do
    {:ok, app} = Borscht.Config.get_env(:app)
    # {:ok, filter_args} = Borscht.Config.get_env(:filter_args)

    %{
      file: format_file(file),
      method: format_method(fun, args),
      args: format_args(args, false),
      number: line,
      context: app_context(app, Application.get_application(mod))
    }
  end

  defp app_context(app, app) when not is_nil(app), do: "app"
  defp app_context(_app1, _app2), do: "all"

  defp format_file(""), do: nil
  defp format_file(file) when is_binary(file), do: file
  defp format_file(file), do: file |> to_string() |> format_file()

  defp format_method(fun, args) when is_list(args) do
    format_method(fun, length(args))
  end

  defp format_method(fun, arity) when is_integer(arity) do
    "#{fun}/#{arity}"
  end

  defp format_args(args, false) when is_list(args) do
    Enum.map(args, &Kernel.inspect(&1, @inspect_opts))
  end

  defp format_args(_args_or_arity, _filter) do
    []
  end
end
