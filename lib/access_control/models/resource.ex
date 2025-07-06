defmodule AccessControl.Resource do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias AccessControl.{Repo, User, Resource, Group, UserResource, UserGroup, GroupResource}

  @primary_key {:id, :binary_id, autogenerate: true}
  @derive {Jason.Encoder, only: [:id, :name]}

  schema "resources" do
    field :name, :string

    has_many(:user_resources, UserResource)
    has_many(:users, through: [:user_resources, :users])

    has_many(:group_resources, AccessControl.GroupResource)
    has_many(:groups, through: [:group_resources, :groups])

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(resource, attrs) do
    resource
    |> cast(attrs, [:id, :name])
    |> validate_required([:name])
    |> unique_constraint(:name)
  end

  def list_resources do
    Resource
    |> Repo.all()
  end

  def get(id) do
    case Ecto.UUID.cast(id) do
      {:ok, _} ->
        Resource
        |> where([r], r.id == ^id)
        |> Repo.one()
        |> case do
          resource = %Resource{} -> {:ok, resource}
          nil -> {:error, :not_found}
        end

      _ ->
        {:error, :bad_request}
    end
  end

  def create_resource(attrs \\ %{}) do
    %Resource{}
    |> Resource.changeset(attrs)
    |> Repo.insert()
  end

  def share_group(%{resource_id: resource_id, group_id: group_id}) do
    %GroupResource{}
    |> GroupResource.changeset(%{group_id: group_id, resource_id: resource_id})
    |> Repo.insert()
  end

  def unshare_group(%{resource_id: resource_id, group_id: group_id}) do
    GroupResource
    |> where([gr], gr.group_id == ^group_id and gr.resource_id == ^resource_id)
    |> Repo.delete_all()
  end

  def share_user(%{resource_id: resource_id, user_id: user_id}) do
    %UserResource{}
    |> UserResource.changeset(%{user_id: user_id, resource_id: resource_id})
    |> Repo.insert()
  end

  def unshare_user(%{resource_id: resource_id, user_id: user_id}) do
    UserResource
    |> where([ur], ur.user_id == ^user_id and ur.resource_id == ^resource_id)
    |> Repo.delete_all()
  end

  def shares(resource_id) do
    # Select all user ids that the resource is directly shared with
    direct_share_user_ids =
      User
      |> join(:left, [u], _ in assoc(u, :user_resources))
      |> join(:left, [_, ur], _ in assoc(ur, :resource))
      |> where([u, ur], ur.resource_id == ^resource_id)
      |> select([u], u.id)

    # Select all the group ids that the resource is shared with
    shared_group_ids =
      Group
      |> join(:left, [g], _ in assoc(g, :group_resources))
      |> join(:left, [_, gr], _ in assoc(gr, :resource))
      |> where([g, gr], gr.resource_id == ^resource_id)
      |> select([g], g.id)

    # Look up the user ids in the resource-shared groups
    users_in_shared_groups =
      User
      |> join(:left, [g], _ in assoc(g, :user_groups))
      |> join(:left, [_, ug], _ in assoc(ug, :user))
      |> where(
        [g, ug],
        ug.group_id in subquery(shared_group_ids)
      )
      |> select([u], u.id)

    # Select only the user ids that are either directly shared, or are members of the shared group
    all_shared_users =
      User
      |> where(
        [u],
        u.id in subquery(direct_share_user_ids) or u.id in subquery(users_in_shared_groups)
      )
      |> Repo.all()

    {:ok, %{user: all_shared_users}}
  end

  def user_count() do
    # All resources initialized with an empty set of shares
    all_resources =
      Resource
      |> Repo.all()
      |> Enum.map(fn resource -> {resource.id, MapSet.new()} end)
      |> Map.new()

    # User group memberships for reverse expansion
    user_group_memberships =
      UserGroup
      |> Repo.all()
      |> Enum.group_by(& &1.group_id)
      |> Enum.map(fn {group_id, memberships} ->
        {group_id, memberships |> Enum.map(fn membership -> membership.user_id end)}
      end)
      |> Map.new()

    # Resources with direct user shares
    user_resources_grouped_by_resource =
      UserResource
      |> Repo.all()
      |> Enum.group_by(& &1.resource_id)
      |> Enum.map(fn {resource_id, user_resources} ->
        {resource_id, user_resources |> Enum.map(fn user_resource -> user_resource.user_id end)}
      end)
      |> Enum.map(fn {resource_id, user_ids} ->
        {resource_id, user_ids |> MapSet.new()}
      end)
      |> Map.new()

    # Resources with group shares, groups expanded to all their users
    group_resources_grouped_by_resource =
      GroupResource
      |> Repo.all()
      |> Enum.group_by(& &1.resource_id)
      |> Enum.map(fn {resource_id, group_resources} ->
        {resource_id,
         group_resources
         |> Enum.map(fn group_resource ->
           group_resource.group_id
         end)}
      end)
      # Convert groups into user memberships
      |> Enum.map(fn {resource_id, group_ids} ->
        {resource_id,
         group_ids
         |> Enum.flat_map(fn group_id ->
           expand_group_to_users(group_id, user_group_memberships)
         end)
         |> MapSet.new()}
      end)
      |> Map.new()

    # Merge direct share users to the group shares in cases where a resource is shared with both
    resources_with_group_and_user_shares =
      group_resources_grouped_by_resource
      |> Enum.map(fn {resource_id, user_ids} ->
        with {:ok, direct_share_users} <-
               Map.fetch(user_resources_grouped_by_resource, resource_id) do
          {resource_id, MapSet.union(user_ids, direct_share_users)}
        else
          _ -> {resource_id, user_ids}
        end
      end)
      |> Map.new()

    # Merge lists together, starting with all resources, then user-only, then group shares. Map.merge replaces values in key collisions, so the last wins
    resources_with_counts =
      Map.merge(all_resources, user_resources_grouped_by_resource)
      |> Map.merge(resources_with_group_and_user_shares)
      |> Enum.map(fn {resource_id, user_ids} ->
        {resource_id, MapSet.size(user_ids)}
      end)
      |> Map.new()

    {:ok, resources_with_counts}
  end

  defp expand_group_to_users(group_id, user_group_memberships) do
    with {:ok, users} <- Map.fetch(user_group_memberships, group_id) do
      users
    else
      _ -> []
    end
  end
end
