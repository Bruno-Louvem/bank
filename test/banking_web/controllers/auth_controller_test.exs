defmodule BankingWeb.AuthControllerTest do
  use BankingWeb.ConnCase

  alias Banking.Auth

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "authenticate user" do
    setup do
      attrs = %{"email" => Faker.Internet.email(), "password" => Faker.String.base64()}
      {:ok, user} = Auth.create_user(attrs)
      [user: user]
    end

    test "renders token when data is valid", %{conn: conn, user: user} do
      signin_map = %{"email" => user.email, "password" => user.password}

      conn = post(conn, Routes.v1_auth_path(conn, :signin), signin_map)
      response = json_response(conn, 200)
      assert response |> Map.has_key?("token")
    end

    test "not renders token when data is invalid", %{conn: conn, user: user} do
      signin_map = %{"email" => user.email, "password" => Ecto.UUID.generate()}

      conn = post(conn, Routes.v1_auth_path(conn, :signin), signin_map)
      response = json_response(conn, 401)
      assert response |> Map.has_key?("errors")
    end
  end
end
