use Mix.Config

config :borscht,
  enabled: true,
  environment_name: :test,
  exclude_environments: [:dev]
