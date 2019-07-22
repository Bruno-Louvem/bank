defmodule BankingWeb.V1.TransactionController do
  use BankingWeb, :controller

  alias Banking.Bank

  action_fallback BankingWeb.FallbackController

  def deposit(conn, %{"amount" => amount, "account_id" => account_id}) do

    with {:ok, account} <- account_id |> Bank.get_account(),
         {:ok, account, transaction} <- account |> Bank.deposit(amount) do
      conn
      |> send_transaction_response("deposit", transaction, account)
    end
  end

  def deposit(_, _), do: {:error, "Invalid amount", 442}

  def withdrawal(conn, %{"amount" => amount, "account_id" => account_id}) do
    user_api_account = conn.assigns.current_user.account
    with true <- user_api_account.id == account_id,
         {:ok, account} <- account_id |> Bank.get_account(),
         {:ok, account, transaction} <- account |> Bank.withdrawal(amount) do
      conn
      |> send_transaction_response("withdrawal", transaction, account)
    else
      false -> {:error, "You just make withdrawal from your account", 403}
      error -> error
    end
  end

  def transfer(conn, %{"amount" => amount, "account_from_id" => account_a_id, "account_to_id" => account_b_id}) do
    user_api_account = conn.assigns.current_user.account
    with true <- user_api_account.id == account_a_id,
         {:ok, account_a} <- account_a_id |> Bank.get_account(),
         {:ok, account_b} <- account_b_id |> Bank.get_account(),
         {:ok, %{transaction_a: t_a, transaction_b: t_b}} <-
           account_a |> Bank.transfer(account_b, amount) do
      conn
      |> render("transfer.json", type: "transfer", transaction_a: t_a, transaction_b: t_b)
    else
      false -> {:error, "You just make transfers from your account", 403}
      error -> error
    end
  end

  defp send_transaction_response(conn, transaction_type, transaction, account) do
    conn
    |> render("transaction.json",
      transaction: %{
        account_id: account.id,
        amount: transaction.amount,
        transaction_id: transaction.id,
        type: transaction_type,
        date: transaction.inserted_at
      }
    )
  end

  def balance(conn, %{"account_id" => account_id}) do
    with {:ok, _} <- account_id |> Bank.get_account(),
          %Money{} = balance <- account_id |> Bank.calc_balance()
    do
      conn |> render("balance.json", balance: balance, account_id: account_id)
    end
  end
end
