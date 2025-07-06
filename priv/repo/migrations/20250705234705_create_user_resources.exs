defmodule AccessControl.Repo.Migrations.CreateUserResources do
  use Ecto.Migration

  def change do
    create table(:user_resources) do
      add :user_id, references(:users, column: :id, type: :binary_id)
      add :resource_id, references(:resources, column: :id, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:user_resources, [:user_id, :resource_id])
  end
end
