defmodule Banking.Auth do
  @moduledoc """
    Main module of Auth context.
    This module has the authetication functions and user management functions
  """
  import Ecto.Query, warn: false
  alias Banking.Repo
  alias Banking.Auth.{Guardian, User}

  @doc """
  Return one user by id.

  ## Examples

      iex> get_user(user_id)
      %User{}


  """
  def get_user(user_id) do
    User
    |> Repo.get(user_id)
    |> Repo.preload([:account])
    |> format_response()
  end

  defp format_response(%User{} = user), do: {:ok, user}
  defp format_response(_), do: {:error, "User not found", 404}

  @doc """
  Return one user by email.

  ## Examples

      iex> get_user(user_id)
      %User{}


  """
  def get_user_by_email(email) do
    User
    |> Repo.get_by(email: email)
    |> Repo.preload([:account])
    |> format_response()
  end

  @doc """
  Creates a account.

  ## Examples

      iex> create_user(%{field: value})
      {:ok, %User{}}

      iex> create_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(attrs) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Authenticates a user
  Returns {:ok, instance, token} | {:error, message}
  """
  def authenticate_user(email, given_password) do
    email
    |> get_user_by_email()
    |> check_password(given_password)
  end

  defp check_password({:ok, %User{password_hash: pw_hash} = user}, given_password)
       when not is_nil(pw_hash) do
    with true <- Comeonin.Bcrypt.checkpw(given_password, pw_hash),
         {:ok, token, _token_data} <- Guardian.encode_and_sign(user) do
      {:ok, user, token}
    else
      _ -> {:error, "unauthenticated", 401}
    end
  end

  defp check_password(_, _), do: {:error, "unauthenticated", 401}
end
