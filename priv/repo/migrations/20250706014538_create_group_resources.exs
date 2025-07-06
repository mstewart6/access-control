defmodule AccessControl.Repo.Migrations.CreateGroupResources do
  use Ecto.Migration

  def change do
    create table(:group_resources) do
      add :group_id, references(:groups, column: :id, type: :binary_id)
      add :resource_id, references(:resources, column: :id, type: :binary_id)

      timestamps(type: :utc_datetime)
    end

    create unique_index(:group_resources, [:group_id, :resource_id])
  end
end
