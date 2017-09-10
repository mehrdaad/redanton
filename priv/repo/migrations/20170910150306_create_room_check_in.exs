defmodule Danton.Repo.Migrations.CreateRoomCheckIn do
  use Ecto.Migration

  def change do
    create table(:room_check_ins) do
      add :room_id, references(:rooms, on_delete: :nothing)
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end

    create index(:room_check_ins, [:room_id])
    create index(:room_check_ins, [:user_id])
  end
end
