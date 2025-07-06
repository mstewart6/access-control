defmodule AccessControlWeb.UserController do
  use AccessControlWeb, :controller

  alias AccessControl.User

  def index(conn, _params) do
    users = User.list_users()
    json(conn, %{users: users})
  end

  def show(conn, %{"id" => id}) do
    with {:ok, user} <- User.get(id) do
      json(conn, user)
    else
      {:error, msg} ->
        conn |> put_status(msg) |> json(%{error: msg})
    end
  end

  def create(conn, %{"user" => user_params}) do
    with {:ok, %{create_user: user}} <- User.create_user(user_params) do
      json(conn, %{user: user})
    else
      {:error, problem} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: problem})
    end
  end

  def user_resources(conn, %{"id" => id}) do
    with {:ok, user_resources} <- User.resources(id) do
      conn
      |> json(%{resources: user_resources})
    else
      {:error, msg} ->
        conn |> put_status(msg) |> json(%{error: msg})
    end
  end

  def resource_count(conn, _) do
    with {:ok, users} <- User.resource_count() do
      conn
      |> json(users)
    end
  end
end
