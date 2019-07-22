defmodule Banking.Bank.Query do
  @moduledoc """
  Custom queries for Bank context
  """
  import Ecto.Query

  alias Banking.Bank.Transaction

  def all_transaction_by_account_id(account_id) do
    from transactions in Transaction,
      where: transactions.account_id == ^account_id
  end
end
