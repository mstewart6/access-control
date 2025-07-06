defmodule AccessControl.Repo.Migrations.CreateResources do
  use Ecto.Migration

  def change do
    create table(:resources, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:resources, :name)
  end
end
