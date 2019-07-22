defmodule BankingWeb.TransactionControllerTest do
  use BankingWeb.ConnCase

  import Banking.Factory

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
    [jwt_account_token: jwt_account_token()]
  end

  describe "deposit" do
    test "deposit amount", %{conn: conn, jwt_account_token: jwt_account_token} do
      conn = conn |> put_req_header("authorization", "Bearer #{jwt_account_token}")
      account = insert(:account)

      conn = post(conn, Routes.v1_transaction_path(conn, :deposit), %{amount: 50_000, account_id: account.id})

      payload = json_response(conn, 200)

      assert payload["type"] == "deposit"
      assert payload |> Map.has_key?("account_id")
      assert payload |> Map.has_key?("transaction_id")
    end

    test "no deposit amount, why? not pass amount on payload", %{
      conn: conn,
      jwt_account_token: jwt_account_token
    } do
      conn = conn |> put_req_header("authorization", "Bearer #{jwt_account_token}")
      account = insert(:account)

      conn = post(conn, Routes.v1_transaction_path(conn, :deposit), %{account_id: account.id})

      payload = json_response(conn, 442)
      assert payload |> Map.has_key?("errors")

      conn = post(conn, Routes.v1_transaction_path(conn, :deposit), %{account_id: Ecto.UUID.generate, amount: 50_000})

      payload = json_response(conn, 404)
      assert payload |> Map.has_key?("errors")
    end

    test "no deposit amount, why? unauthenticated user", %{conn: conn} do
      conn = conn |> put_req_header("authorization", "Bearer #{Ecto.UUID.generate()}")
      conn = post(conn, Routes.v1_transaction_path(conn, :deposit), %{amount: 50_000})

      payload = json_response(conn, 401)
      assert payload |> Map.has_key?("errors")
    end
  end

  describe "withdrawal" do
    test "withdrawal amount", %{conn: conn} do
      account = insert(:account)
      jwt_account_token = jwt_account_token(%{user: account.user})
      conn = conn |> put_req_header("authorization", "Bearer #{jwt_account_token}")


      conn = post(conn, Routes.v1_transaction_path(conn, :deposit), %{amount: 50_000, account_id: account.id})
      conn = post(conn, Routes.v1_transaction_path(conn, :withdrawal), %{amount: 40_000, account_id: account.id})

      payload = json_response(conn, 200)

      assert payload["type"] == "withdrawal"
      assert payload |> Map.has_key?("account_id")
      assert payload |> Map.has_key?("transaction_id")
    end

    test "withdrawal not work. Why? insuficient balance",
         %{conn: conn} do
      account = insert(:account)
      jwt_account_token = jwt_account_token(%{user: account.user})
      conn = conn |> put_req_header("authorization", "Bearer #{jwt_account_token}")

      conn = post(conn, Routes.v1_transaction_path(conn, :deposit), %{account_id: account.id, amount: 30_000})
      conn = post(conn, Routes.v1_transaction_path(conn, :withdrawal), %{account_id: account.id, amount: 40_000})

      payload = json_response(conn, 500)
      assert payload |> Map.has_key?("errors")
    end

    test "withdrawal not work. Why? another account id",
         %{conn: conn, jwt_account_token: jwt_account_token} do
      conn = conn |> put_req_header("authorization", "Bearer #{jwt_account_token}")
      account = insert(:account)

      conn = post(conn, Routes.v1_transaction_path(conn, :deposit), %{account_id: account.id, amount: 30_000})
      conn = post(conn, Routes.v1_transaction_path(conn, :withdrawal), %{account_id: account.id, amount: 40_000})

      payload = json_response(conn, 403)
      assert payload |> Map.has_key?("errors")
    end
  end

  describe "transfer" do
    test "transfer to another account", %{conn: conn, jwt_account_token: jwt_account_token_2} do

      account = insert(:account)
      jwt_account_token = jwt_account_token(%{user: account.user})
      conn = conn |> put_req_header("authorization", "Bearer #{jwt_account_token}")

      conn =
        post(conn, Routes.v1_transaction_path(conn, :deposit),
           %{account_id: account.id, amount: 30_000})

      account_params = %{
        name: Faker.Name.name(),
        email: Faker.Internet.email(),
        password: Faker.String.base64()
      }

      conn = post(conn, Routes.v1_account_path(conn, :create), account_params)
      response = json_response(conn, 201)

      {:ok, account_b_id} = response |> Map.fetch("id")

      transfer_params = %{
        account_from_id: account.id,
        account_to_id: account_b_id,
        amount: 10_000
      }

      conn = post(conn, Routes.v1_transaction_path(conn, :transfer), transfer_params |> Map.merge(%{amount: 30_001}))
      assert json_response(conn, 500) |> Map.has_key?("errors")

      new_conn = build_conn() |> put_req_header("authorization", "Bearer #{jwt_account_token_2}")
      new_conn = post(new_conn, Routes.v1_transaction_path(new_conn, :transfer), transfer_params)
      assert json_response(new_conn, 403) |> Map.has_key?("errors")

      conn = post(conn, Routes.v1_transaction_path(conn, :transfer), transfer_params)
      %{"transactions" => [transaction_a, transaction_b]} = json_response(conn, 200)

      assert transaction_a["transaction_id"] != transaction_b["transaction_id"]
      assert transaction_a["account_id"] != transaction_b["account_id"]

      amount_a = transaction_a["amount"] |> Money.parse!(:BRL)
      amount_b = transaction_b["amount"] |> Money.parse!(:BRL)

      assert amount_a |> Money.add(amount_b) |> Money.equals?(Money.new(0))
    end
  end

  describe "balance" do
    test "get balance", %{conn: conn, jwt_account_token: jwt_account_token} do
      conn = conn |> put_req_header("authorization", "Bearer #{jwt_account_token}")
      account = insert(:account)
      conn = post(conn, Routes.v1_transaction_path(conn, :deposit), %{amount: 30_000, account_id: account.id})
      conn = get(conn, Routes.v1_transaction_path(conn, :balance, account.id))
      %{"balance" => balance, "account_id" => _} = json_response(conn, 200)

      parsed_balance = balance |> Money.parse!(:BRL)

      assert parsed_balance |> Money.equals?(Money.new(30_000))
    end

    test "no get balance. why? account does not exist", %{conn: conn, jwt_account_token: jwt_account_token} do
      conn = conn |> put_req_header("authorization", "Bearer #{jwt_account_token}")
      conn = get(conn, Routes.v1_transaction_path(conn, :balance, Ecto.UUID.generate()))
      response = json_response(conn, 404)

      assert response |> Map.has_key?("errors")
    end
  end
end
