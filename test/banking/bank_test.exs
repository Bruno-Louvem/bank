defmodule Banking.BankTest do
  use Banking.DataCase

  alias Banking.Bank
  alias Banking.Bank.{Account}

  import Banking.Factory

  @valid_user_attrs %{"email" => Faker.Internet.email(), "password" => Faker.String.base64()}
  @valid_account_attrs %{"name" => Faker.Name.name()}
  @invalid_account_attrs %{"name" => nil}

  describe "accounts" do
    test "list_accounts/0 returns all accounts" do
      account = insert(:account)
      [loaded_account] = Bank.list_account()
      assert loaded_account.id == account.id
    end

    test "get account" do
      account = insert(:account)

      assert {:ok, _} = account.id |> Bank.get_account()
    end

    test "not get account. why? not found account id" do
      assert {:error, _, 404} = Ecto.UUID.generate() |> Bank.get_account()
    end

    test "create_account/1 with valid data creates a account" do
      user = insert(:user)
      account_attr = @valid_account_attrs |> Map.merge(%{"user_id" => user.id})
      assert {:ok, %Account{} = account} = Bank.create_account(account_attr)
      assert account.name == @valid_account_attrs["name"]
    end

    test "create_account/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Bank.create_account(@invalid_account_attrs)
    end

    test "test signup" do
      signup_attr = @valid_account_attrs |> Map.merge(@valid_user_attrs)
      assert {:ok, %Account{} = account} = Bank.signup(signup_attr)
    end

    test "test signup with invalid attrs" do
      assert {:error, %Ecto.Changeset{}} = Bank.signup(@invalid_account_attrs)
    end
  end
end
