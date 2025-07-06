defmodule AccessControl.UserGroup do
  use Ecto.Schema
  import Ecto.Changeset

  alias AccessControl.{User, Group}

  @derive {Jason.Encoder, only: [:id, :user_id, :group_id]}

  schema "user_groups" do
    belongs_to :user, User, references: :id, type: :binary_id
    belongs_to :group, Group, references: :id, type: :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user_group, attrs) do
    user_group
    |> cast(attrs, [:user_id, :group_id])
    |> validate_required([:user_id, :group_id])
    |> unique_constraint([:user_id, :group_id])
  end
end
