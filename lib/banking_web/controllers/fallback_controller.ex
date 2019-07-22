defmodule BankingWeb.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use BankingWeb, :controller

  def call(conn, {:error, message, code}) do
    conn
    |> put_status(code)
    |> put_view(BankingWeb.ErrorView)
    |> render("#{code}.json", error: %{message: message})
  end

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(BankingWeb.ChangesetView)
    |> render("error.json", changeset: changeset)
  end
end
