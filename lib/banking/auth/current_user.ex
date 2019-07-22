defmodule Banking.Auth.CurrentUser do
  @moduledoc false
  def init(_opts), do: :ok

  def call(conn, _opts) do
    current_user = Guardian.Plug.current_resource(conn)
    Plug.Conn.assign(conn, :current_user, current_user)
  end
end
