defmodule Banking.Auth.Pipeline do
  @moduledoc """
  Pipeline that ensures the user is authenticated
  """

  use Guardian.Plug.Pipeline,
    otp_app: :banking,
    error_handler: Banking.Auth.ErrorHandler,
    module: Banking.Auth.Guardian

  plug Guardian.Plug.VerifyHeader, realm: "Bearer"
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource
  plug Banking.Auth.CurrentUser
end
