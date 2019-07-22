defmodule Banking.Bank do
  @moduledoc """
  The Bank context.
  """

  import Ecto.Query, warn: false
  alias Banking.Auth
  alias Banking.Repo
  alias Banking.Bank.{Account, Query, Transaction}

  @doc """
  Returns the list of account.

  ## Examples

      iex> list_account()
      [%Account{}, ...]

  """
  def list_account do
    Account
    |> Repo.all()
  end

  @doc """
  Returns the list of account.

  ## Examples

      iex> get_account(account_id)
      %Account{}

  """
  def get_account(account_id) do
    Account
    |> Repo.get(account_id)
    |> format_response()
  end

  defp format_response(%Account{} = account), do: {:ok, account}
  defp format_response(_), do: {:error, "Account not found", 404}

  @doc """
  Creates a account.

  ## Examples

      iex> create_account(%{field: value})
      {:ok, %Account{}}

      iex> create_account(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_account(attrs \\ %{}) do
    %Account{}
    |> Account.changeset(attrs)
    |> Repo.insert()
  end

  @spec signup(:invalid | %{optional(:__struct__) => none, optional(atom | binary) => any}) :: any
  def signup(signup_attrs) do
    with {:ok, user} <- signup_attrs |> Auth.create_user(),
         {:ok, account} <- signup_attrs |> Map.merge(%{"user_id" => user.id}) |> create_account()
    do
      account =
          account
          |> Repo.preload(:user, force: true)
      {:ok, account}
    end
  end

  @spec deposit(Banking.Bank.Account.t(), any) :: nil
  def deposit(%Account{id: account_id} = account, %Money{} = amount) do
    transaction_attrs = %{account_id: account_id, amount: amount}

    with {:ok, _} <- account_id |> validate_balance_change(amount),
         {:ok, transaction} <- transaction_attrs |> create_transaction() do
      account =
        account
        |> Repo.preload(:user, force: true)

      {:ok, account, transaction}
    end
  end

  def deposit(%Account{} = account, amount) when is_integer(amount) do
    account
    |> deposit(amount |> Money.new())
  end

  def deposit(_, _), do: {:error, "Invalid account to be accredited", 500}

  @spec create_transaction(
          :invalid
          | %{optional(:__struct__) => none, optional(atom | binary) => any}
        ) :: any
  def create_transaction(attrs \\ %{}) do
    %Transaction{}
    |> Transaction.changeset(attrs)
    |> Repo.insert()
  end

  def calc_balance(account_id) do
    account_id
    |> Query.all_transaction_by_account_id()
    |> Repo.all()
    |> Enum.reduce(Money.new(0), fn t, acc -> acc |> Money.add(t.amount) end)
  end

  defp validate_balance_change(account_id, amount) do
    balance = account_id |> calc_balance() |> Money.add(amount)

    if balance |> Money.positive?() do
      {:ok, balance}
    else
      {:error, "Insuficient funds", 500}
    end
  end

  @spec withdrawal(Banking.Bank.Account.t(), any) :: nil
  def withdrawal(%Account{id: account_id} = account, %Money{} = amount) do
    amount =
      amount
      |> Money.abs()
      |> Money.neg()

    transaction_attrs = %{account_id: account_id, amount: amount}

    with {:ok, _} <- account_id |> validate_balance_change(amount),
         {:ok, transaction} <- transaction_attrs |> create_transaction() do
      account =
        account
        |> Repo.preload(:user, force: true)

      {:ok, account, transaction}
    end
  end

  def withdrawal(%Account{} = account, amount) when is_integer(amount) do
    account |> withdrawal(amount |> Money.new())
  end

  def withdrawal(_, _), do: {:error, "Invalid Params", 500}

  @spec transfer(Banking.Bank.Account.t(), Banking.Bank.Account.t(), integer | Money.t()) :: any
  def transfer(%Account{id: account_a_id}, %Account{id: account_b_id}, %Money{} = amount) do
    amount_a =
      amount
      |> Money.abs()
      |> Money.neg()

    amount_b =
      amount
      |> Money.abs()

    transaction_a_attrs = %{account_id: account_a_id, amount: amount_a}
    transaction_b_attrs = %{account_id: account_b_id, amount: amount_b}

    Repo.transaction(fn ->
      with {:ok, _} <- account_a_id |> validate_balance_change(amount_a),
           {:ok, _} <- account_b_id |> validate_balance_change(amount_b),
           {:ok, transaction_a} <- transaction_a_attrs |> create_transaction(),
           {:ok, transaction_b} <- transaction_b_attrs |> create_transaction() do
        %{
          transaction_a: %{
            transaction_id: transaction_a.id,
            account_id: account_a_id,
            amount: transaction_a.amount,
            date: transaction_a.inserted_at
          },
          transaction_b: %{
            transaction_id: transaction_b.id,
            account_id: account_b_id,
            amount: transaction_b.amount,
            date: transaction_b.inserted_at
          }
        }
      else
        {:error, message, _} ->
          Repo.rollback("Transfer not allowed: #{message}")
      end
    end)
    |> case  do
      {:error, message} -> {:error, message, 500}
      response -> response
    end
  end

  def transfer(%Account{} = account_a, %Account{} = account_b, amount) when amount |> is_integer do
    amount = amount |> Money.new()

    account_a
    |> transfer(account_b, amount)
  end

  def transfer(_, _, _), do: {:error, "Invalid Params", 500}
end
