defmodule AccessControl.User do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias Ecto.Multi
  alias AccessControl.{Repo, User, Resource, Group, UserResource, GroupResource, UserGroup}

  @primary_key {:id, :binary_id, autogenerate: true}
  @derive {Jason.Encoder, only: [:id, :username, :first_name, :last_name]}

  schema "users" do
    field :username, :string
    field :first_name, :string
    field :last_name, :string

    has_many(:user_resources, UserResource)
    has_many(:resources, through: [:user_resources, :resources])

    has_many(:user_groups, AccessControl.UserGroup)
    has_many(:groups, through: [:user_groups, :groups])

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:id, :first_name, :last_name, :username])
    |> validate_required([:first_name, :last_name, :username])
    |> unique_constraint(:username)
  end

  def create_user(attrs \\ %{}) do
    new_user =
      %User{}
      |> User.changeset(attrs)

    everyone_group =
      Group
      |> where([g], g.name == "Everyone")
      |> Repo.one()

    Multi.new()
    |> Multi.insert(:create_user, new_user)
    |> Multi.insert(:everyone_membership, fn %{create_user: %User{id: user_id}} ->
      UserGroup.changeset(
        %UserGroup{},
        %{user_id: user_id, group_id: everyone_group.id}
      )
    end)
    |> Repo.transaction()
  end

  def list_users() do
    User
    |> Repo.all()
  end

  def get(id) do
    case Ecto.UUID.cast(id) do
      {:ok, _} ->
        User
        |> where([u], u.id == ^id)
        |> Repo.one()
        |> case do
          user = %User{} -> {:ok, user}
          nil -> {:error, :not_found}
        end

      _ ->
        {:error, :bad_request}
    end
  end

  def resources(user_id) do
    # Select all resource_ids that are directly shared with the user
    direct_share_resource_ids =
      Resource
      |> select([r], r.id)
      |> join(:left, [r], _ in assoc(r, :user_resources))
      |> join(:left, [_, ur], _ in assoc(ur, :resource))
      |> where([u, ur], ur.user_id == ^user_id)

    # Look up all the group ids that the user is a member of
    groups_for_user =
      Group
      |> select([g], g.id)
      |> join(:left, [u], _ in assoc(u, :user_groups))
      |> join(:left, [_, ug], _ in assoc(ug, :user))
      |> where([u, ug], ug.user_id == ^user_id)

    # Look up all resource ids shared with the user group memeberships
    group_shared_resource_ids =
      Resource
      |> select([r], r.id)
      |> join(:left, [r], _ in assoc(r, :group_resources))
      |> join(:left, [_, gr], _ in assoc(gr, :resource))
      |> where([g, gr], gr.group_id in subquery(groups_for_user))

    # Select only the resources that are either directly shared, or shared with a group the user is a member of
    all_shared_resources =
      Resource
      |> where(
        [r],
        r.id in subquery(direct_share_resource_ids) or r.id in subquery(group_shared_resource_ids)
      )
      |> Repo.all()

    {:ok, all_shared_resources}
  end

  def resource_count() do
    # All users initialized with an empty set of shares
    all_users =
      User
      |> Repo.all()
      |> Enum.map(fn user -> {user.id, MapSet.new()} end)
      |> Map.new()

    # User group memberships for reverse expansion
    user_group_memberships =
      UserGroup
      |> Repo.all()
      |> Enum.group_by(& &1.user_id)
      |> Enum.map(fn {user_id, memberships} ->
        {user_id, memberships |> Enum.map(fn membership -> membership.group_id end)}
      end)
      |> Map.new()

    # Resources with direct user shares
    user_resources_grouped_by_user =
      UserResource
      |> Repo.all()
      |> Enum.group_by(& &1.user_id)
      |> Enum.map(fn {user_id, user_resources} ->
        {user_id, user_resources |> Enum.map(fn user_resource -> user_resource.resource_id end)}
      end)
      |> Enum.map(fn {user_id, resource_ids} ->
        {user_id, resource_ids |> MapSet.new()}
      end)
      |> Map.new()

    # Groups with their resources
    group_resources_grouped_by_group =
      GroupResource
      |> Repo.all()
      |> Enum.group_by(& &1.group_id)
      |> Enum.map(fn {group_id, group_resources} ->
        {group_id,
         group_resources
         |> Enum.map(fn group_resource ->
           group_resource.resource_id
         end)}
      end)
      |> Enum.map(fn {group_id, resource_ids} ->
        {group_id, resource_ids |> MapSet.new()}
      end)
      |> Map.new()

    # Expand users into their groups for the resources shared with the groups
    users_with_group_shared_resources =
      user_group_memberships
      |> Enum.map(fn {user_id, group_ids} ->
        {user_id,
         group_ids
         |> Enum.flat_map(fn group_id ->
           expand_group_to_resources(group_id, group_resources_grouped_by_group)
         end)
         |> MapSet.new()}
      end)

    # Merge direct share users to the group shares in cases where a resource is shared with both
    users_with_group_and_user_shared_resources =
      users_with_group_shared_resources
      |> Enum.map(fn {user_id, resource_ids} ->
        with {:ok, direct_share_resources} <- Map.fetch(user_resources_grouped_by_user, user_id) do
          {user_id, MapSet.union(resource_ids, direct_share_resources)}
        else
          _ -> {user_id, MapSet.new(resource_ids)}
        end
      end)
      |> Map.new()

    # Merge lists together, starting with all users, then user-only, then group shares. Map.merge replaces values in key collisions, so the last wins
    users_with_counts =
      Map.merge(all_users, user_resources_grouped_by_user)
      |> Map.merge(users_with_group_and_user_shared_resources)
      |> Enum.map(fn {user_id, resource_ids} ->
        {user_id, MapSet.size(resource_ids)}
      end)
      |> Map.new()

    {:ok, users_with_counts}
  end

  defp expand_group_to_resources(group_id, group_resources_grouped_by_group) do
    with {:ok, resources} <- Map.fetch(group_resources_grouped_by_group, group_id) do
      resources
    else
      _ -> []
    end
  end
end
