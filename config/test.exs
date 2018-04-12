use Mix.Config

config :borscht,
  enabled: true,
  app: :aaa,
  environment_name: Mix.env(),
  exclude_envs: [:dev, :test],
  reporters: [
    Borscht.Reporters.Console
  ]
