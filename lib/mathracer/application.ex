defmodule Mathracer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      MathracerWeb.Endpoint,
      worker(Mathracer.GameServer, [])
    ]

    opts = [strategy: :one_for_one, name: Mathracer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    MathracerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
