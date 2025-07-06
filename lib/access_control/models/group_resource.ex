defmodule AccessControl.GroupResource do
  use Ecto.Schema
  import Ecto.Changeset

  alias AccessControl.{Group, Resource}

  schema "group_resources" do
    belongs_to :group, Group, references: :id, type: :binary_id
    belongs_to :resource, Resource, references: :id, type: :binary_id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(group_resource, attrs) do
    group_resource
    |> cast(attrs, [:group_id, :resource_id])
    |> validate_required([:group_id, :resource_id])
    |> unique_constraint([:group_id, :resource_id])
  end
end
