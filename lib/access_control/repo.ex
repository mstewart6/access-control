defmodule AccessControl.Repo do
  use Ecto.Repo,
    otp_app: :access_control,
    adapter: Ecto.Adapters.Postgres
end
