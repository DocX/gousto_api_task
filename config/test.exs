use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :gousto_api_task, GoustoApiTask.Endpoint,
  http: [host: "example.com", port: 80],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn
