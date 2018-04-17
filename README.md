# Borscht

<img src="https://cdn.rawgit.com/BlueHotDog/borscht/13b13c94/assets/logo.png" alt="Logo" width=200px/>

Plugin based exception tracking for Elixir.
After looking at various exception tracking tools in Elixir i noticed that most of them include the same code, 
with various degrees of tests and functionality implemented.
The goal is to have this lib handle all the heavy lifting of catching the exception and have tiny wrappers for Honeybadger/Bugsnag etc for reporting.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `borscht` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:borscht, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/borscht](https://hexdocs.pm/borscht).

