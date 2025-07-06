defmodule AccessControlWeb.ResourceController do
  use AccessControlWeb, :controller

  alias AccessControl.Resource

  def index(conn, _params) do
    resources = Resource.list_resources()

    conn
    |> json(%{resources: resources})
  end

  def show(conn, %{"id" => id}) do
    with {:ok, resource} <- Resource.get(id) do
      conn
      |> json(resource)
    else
      {:error, msg} ->
        conn |> put_status(msg) |> json(%{error: msg})
    end
  end

  def create(conn, %{"resource" => resource_params}) do
    with {:ok, resource} <- Resource.create_resource(resource_params) do
      conn
      |> json(%{resource: resource})
    else
      {:error, problem} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: problem})
    end
  end

  def access_list(conn, %{"id" => id}) do
    with {:ok, shares} <- Resource.shares(id) do
      conn
      |> json(shares)
    else
      {:error, msg} ->
        conn |> put_status(msg) |> json(%{error: msg})
    end
  end

  def share_group(conn, %{"id" => resource_id, "group_id" => group_id}) do
    with {:ok, _} <-
           Resource.share_group(%{resource_id: resource_id, group_id: group_id}) do
      conn
      |> put_status(:no_content)
      |> json(%{})
    else
      {:error, problem} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: problem})
    end
  end

  def unshare_group(conn, %{"id" => resource_id, "group_id" => group_id}) do
    Resource.unshare_group(%{resource_id: resource_id, group_id: group_id})

    conn
    |> put_status(:no_content)
    |> json(%{})
  end

  def share_user(conn, %{"id" => resource_id, "user_id" => user_id}) do
    with {:ok, _} <-
           Resource.share_user(%{resource_id: resource_id, user_id: user_id}) do
      conn
      |> put_status(:no_content)
      |> json(%{})
    else
      {:error, problem} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: problem})
    end
  end

  def unshare_user(conn, %{"id" => resource_id, "user_id" => user_id}) do
    Resource.unshare_user(%{resource_id: resource_id, user_id: user_id})

    conn
    |> put_status(:no_content)
    |> json(%{})
  end

  def user_count(conn, _) do
    with {:ok, resources} <- Resource.user_count() do
      conn
      |> json(resources)
    end
  end
end
