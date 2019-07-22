defmodule BankingWeb.AccountControllerTest do
  use BankingWeb.ConnCase

  import Banking.Factory

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
    [jwt_account_token: jwt_account_token()]
  end

  describe "index" do
    test "lists all accounts without accounts created", %{
      conn: conn,
      jwt_account_token: jwt_account_token
    } do
      conn = conn |> put_req_header("authorization", "Bearer #{jwt_account_token}")
      conn = get(conn, Routes.v1_account_path(conn, :index))
      assert conn |> json_response(200) |> length() == 1
    end

    test "lists all accounts", %{conn: conn, jwt_account_token: jwt_account_token} do
      conn = conn |> put_req_header("authorization", "Bearer #{jwt_account_token}")

      1..10
      |> Enum.each(&insert(:account, name: "Account #{&1}"))

      conn = get(conn, Routes.v1_account_path(conn, :index))
      account_list = json_response(conn, 200)
      assert account_list |> length() == 11
    end
  end

  describe "create" do
    test "create account", %{conn: conn, jwt_account_token: jwt_account_token} do
      conn = conn |> put_req_header("authorization", "Bearer #{jwt_account_token}")

      account_params = %{
        name: Faker.Name.name(),
        email: Faker.Internet.email(),
        password: Faker.String.base64()
      }

      conn = post(conn, Routes.v1_account_path(conn, :create), account_params)
      response = json_response(conn, 201)

      assert response["name"] == account_params.name
      assert response |> Map.has_key?("id")
    end

    test "not create account. why? invalid params", %{
      conn: conn,
      jwt_account_token: jwt_account_token
    } do
      conn = conn |> put_req_header("authorization", "Bearer #{jwt_account_token}")

      conn = post(conn, Routes.v1_account_path(conn, :create), %{})
      response = json_response(conn, 422)
      assert response |> Map.has_key?("errors")
    end
  end
end
