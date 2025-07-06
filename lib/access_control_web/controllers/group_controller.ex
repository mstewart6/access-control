defmodule AccessControlWeb.GroupController do
  use AccessControlWeb, :controller

  alias AccessControl.Group

  def index(conn, _params) do
    groups = Group.list_groups()
    json(conn, %{groups: groups})
  end

  def create(conn, %{"group" => group_params}) do
    with {:ok, group} <- Group.create_group(group_params) do
      conn
      |> json(%{group: group})
    else
      {:error, problem} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: problem})
    end
  end

  def add_user(conn, %{"id" => group_id, "user_id" => user_id}) do
    with {:ok, _} <-
           Group.add_user(%{group_id: group_id, user_id: user_id}) do
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

  def remove_user(conn, %{"id" => group_id, "user_id" => user_id}) do
    Group.remove_user(%{user_id: user_id, group_id: group_id})

    conn
    |> put_status(:no_content)
    |> json(%{})
  end
end
