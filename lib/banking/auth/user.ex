defmodule Banking.Auth.User do
  @moduledoc false
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "users" do
    has_one :account, Banking.Bank.Account
    field :email, :string
    field :password, :string, virtual: true
    field :password_hash, :string
    field :active, :boolean, default: true

    timestamps()
  end

  @required_fields ~w(email password)a

  def changeset(user, attrs) do
    user
    |> cast(attrs, @required_fields)
    |> validate_required(@required_fields)
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
    |> put_pass_hash()
  end

  defp put_pass_hash(changeset) do
    case Map.has_key?(changeset.changes, :password) do
      true ->
        password = changeset.changes.password
        put_change(changeset, :password_hash, Comeonin.Bcrypt.hashpwsalt(password))

      false ->
        changeset
    end
  end
end
