defmodule AccessControl.UserResource do
  use Ecto.Schema
  import Ecto.Changeset

  alias AccessControl.{User, Resource}

  schema "user_resources" do
    belongs_to :user, User, references: :id, type: :binary_id
    belongs_to :resource, Resource, references: :id, type: :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user_resource, attrs) do
    user_resource
    |> cast(attrs, [:user_id, :resource_id])
    |> validate_required([:user_id, :resource_id])
    |> unique_constraint([:user_id, :resource_id])
  end
end
