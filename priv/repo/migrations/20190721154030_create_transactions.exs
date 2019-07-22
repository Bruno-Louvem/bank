defmodule Banking.Repo.Migrations.CreateTransactions do
  use Ecto.Migration

  def change do
    create table(:transactions, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :account_id, references(:accounts, type: :uuid)
      add :amount, :integer

      timestamps(updated_at: false)
    end

    create index(:transactions, [:account_id])
  end
end
