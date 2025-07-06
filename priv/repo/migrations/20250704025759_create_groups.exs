defmodule AccessControl.Repo.Migrations.CreateGroups do
  use Ecto.Migration

  def change do
    create table(:groups, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:groups, :name)
  end
end
