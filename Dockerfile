FROM elixir

RUN bash -c "echo Y | mix local.hex"
WORKDIR /myapp
