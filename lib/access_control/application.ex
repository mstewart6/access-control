defmodule AccessControl.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      AccessControlWeb.Telemetry,
      AccessControl.Repo,
      {DNSCluster, query: Application.get_env(:access_control, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: AccessControl.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: AccessControl.Finch},
      # Start a worker by calling: AccessControl.Worker.start_link(arg)
      # {AccessControl.Worker, arg},
      # Start to serve requests, typically the last entry
      AccessControlWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: AccessControl.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AccessControlWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
