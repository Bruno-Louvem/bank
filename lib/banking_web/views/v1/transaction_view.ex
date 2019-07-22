defmodule BankingWeb.V1.TransactionView do
  use BankingWeb, :view

  alias BankingWeb.V1.TransactionView

  def render("transaction.json", %{transaction: transaction}) do
    %{
      transaction_id: transaction.transaction_id,
      account_id: transaction.account_id,
      amount: transaction.amount |> Money.to_string(),
      date: transaction.date,
      type: transaction.type
    }
  end

  def render("transfer.json", %{type: type, transaction_a: t_a, transaction_b: t_b}) do
    %{
      transactions: [
        render_one(t_a |> Map.put(:type, type), TransactionView, "transaction.json"),
        render_one(t_b |> Map.put(:type, type), TransactionView, "transaction.json")
      ]
    }
  end

  def render("balance.json", %{balance: balance, account_id: account_id}) do
    %{
      balance: balance |> Money.to_string(),
      account_id: account_id
    }
  end
end
