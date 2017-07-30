FROM elixir:1.4.5

WORKDIR /app

RUN mix local.hex --force
RUN mix local.rebar --force
