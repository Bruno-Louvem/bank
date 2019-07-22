defmodule Banking.Auth.ErrorHandler do
  @moduledoc """
  Handles unauthorized requests
  """
  import Plug.Conn

  def auth_error(conn, {type, _reason}, _opts) do
    body = Jason.encode!(%{errors: %{message: "#{type}"}})

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(401, body)
  end
end
