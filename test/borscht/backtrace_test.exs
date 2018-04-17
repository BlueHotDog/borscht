defmodule Borscht.BacktraceTest do
  use Borscht.Case, async: true

  alias Borscht.Backtrace

  doctest Borscht.Backtrace

  test "converting a stacktrace to the Borschts format" do
    stacktrace = [
      {:erlang, :some_func, [{:ok, 123}], []},
      {Honeybadger, :notify, [%RuntimeError{message: "error"}, %{a: 1}, [:a, :b]],
       [file: 'lib/borscht.ex', line: 38]},
      {Honeybadger.Backtrace, :from_stacktrace, 1, [file: 'lib/borscht/backtrace.ex', line: 4]}
    ]

    with_config([filter_args: false], fn ->
      assert [entry_1, entry_2, entry_3] = Backtrace.from_stacktrace(stacktrace)

      assert entry_1 == %{
               file: nil,
               number: nil,
               method: "some_func/1",
               args: ["{:ok, 123}"],
               context: "all"
             }

      assert entry_2 == %{
               file: "lib/borscht.ex",
               number: 38,
               method: "notify/3",
               args: ["%RuntimeError{message: \"error\"}", "%{a: 1}", "[:a, :b]"],
               context: "all"
             }

      assert entry_3 == %{
               file: "lib/borscht/backtrace.ex",
               number: 4,
               method: "from_stacktrace/1",
               args: [],
               context: "all"
             }
    end)
  end

  test "including args can be disabled" do
    stacktrace = [{Borscht, :something, [1, 2, 3], []}]

    with_config([filter_args: true], fn ->
      assert [entry_1] = Backtrace.from_stacktrace(stacktrace)
      assert match?(%{method: "something/3", args: ["1", "2", "3"]}, entry_1)
    end)
  end
end
