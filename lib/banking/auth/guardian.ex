defmodule Banking.Auth.Guardian do
  @moduledoc false

  use Guardian, otp_app: :banking

  alias Banking.Auth

  def subject_for_token(user, _claims) do
    sub = to_string(user.id)
    {:ok, sub}
  end

  def resource_from_claims(claims) do
    id = claims["sub"]
    Auth.get_user(id)
  end
end
