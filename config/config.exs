# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
#config :gousto_api_task

# Configures the endpoint
config :gousto_api_task, GoustoApiTask.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "y2oN7fH6rP7u3pR1fmtwEp9dbkK3uuPCYn+qmdxT4zeNGkC58CmPqSaqn7c1ntUo",
  render_errors: [view: GoustoApiTask.ErrorView, accepts: ~w(json)],
  pubsub: [name: GoustoApiTask.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :phoenix, :format_encoders,
  "json-api": Poison

config :mime, :types, %{
  "application/vnd.api+json" => ["json-api"]
}

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
