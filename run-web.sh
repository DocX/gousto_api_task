#!/bin/bash

cd /myapp

# Initial setup
mix deps.get --only-prod
MIX_ENV=prod mix compile

# Custom tasks (like DB migrations)
# MIX_ENV=prod mix ecto.migrate

# Finally run the server
PORT=4000 MIX_ENV=prod mix phoenix.server
