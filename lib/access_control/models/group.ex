defmodule AccessControl.Group do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias AccessControl.{Repo, Group, GroupResource, UserGroup}

  @primary_key {:id, :binary_id, autogenerate: true}
  @derive {Jason.Encoder, only: [:id, :name]}

  schema "groups" do
    field :name, :string

    has_many(:group_resources, GroupResource)
    has_many(:resources, through: [:group_resources, :resources])

    has_many(:user_groups, AccessControl.UserGroup)
    has_many(:users, through: [:user_groups, :users])

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(group, attrs) do
    group
    |> cast(attrs, [:id, :name])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end

  def list_groups() do
    Group
    |> Repo.all()
  end

  def create_group(attrs \\ %{}) do
    %Group{}
    |> Group.changeset(attrs)
    |> Repo.insert()
  end

  def add_user(%{user_id: user_id, group_id: group_id}) do
    %UserGroup{}
    |> UserGroup.changeset(%{user_id: user_id, group_id: group_id})
    |> Repo.insert()
  end

  def remove_user(%{user_id: user_id, group_id: group_id}) do
    # Don't allow users to be removed from "Everyone"
    everyone_group =
      Group
      |> select([g], g.id)
      |> where([g], g.name == "Everyone")

    UserGroup
    |> where(
      [ug],
      ug.user_id == ^user_id and ug.group_id == ^group_id and
        ug.group_id not in subquery(everyone_group)
    )
    |> Repo.delete_all()
  end
end
