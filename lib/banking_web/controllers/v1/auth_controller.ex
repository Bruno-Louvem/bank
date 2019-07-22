defmodule BankingWeb.V1.AuthController do
  use BankingWeb, :controller

  alias Banking.Auth

  action_fallback BankingWeb.FallbackController

  def signin(conn, %{"email" => email, "password" => password}) do
    with {:ok, _, token} <- email |> Auth.authenticate_user(password) do
      conn
      |> render("auth.json", token: token)
    end
  end
end
