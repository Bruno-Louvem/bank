defmodule Banking.Bank.Transaction do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "transactions" do
    belongs_to :account, Banking.Bank.Account, type: :binary_id

    field :amount, Money.Ecto.Amount.Type

    timestamps(updated_at: false)
  end

  @required_fields ~w(account_id amount)a

  @doc false
  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
  end
end
