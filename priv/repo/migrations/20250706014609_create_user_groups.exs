defmodule AccessControl.Repo.Migrations.CreateUserGroups do
  use Ecto.Migration

  def change do
    create table(:user_groups) do
      add :user_id, references(:users, column: :id, type: :binary_id)
      add :group_id, references(:groups, column: :id, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:user_groups, [:user_id, :group_id])
  end
end
