defmodule Banking.Factory do
  @moduledoc """
    Module responsible to provide helper funcions for entity creations on tests
  """
  import Banking.Utils, only: [recursive_struct_to_map: 1]

  alias Banking.Auth
  alias Banking.Bank
  alias Banking.Repo

  def jwt_account_token do
    user = insert(:user)
    insert(:account, context: %{user: user})
    {:ok, jwt_account_token, _} = Auth.Guardian.encode_and_sign(user)
    jwt_account_token
  end

  def jwt_account_token(%{user: %Banking.Auth.User{} = user}) do
    {:ok, jwt_account_token, _} = Auth.Guardian.encode_and_sign(user)
    jwt_account_token
  end

  defp entity(_context, :user) do
    %Auth.User{
      email: Faker.Internet.email(),
      password_hash: Faker.String.base64()
    }
  end

  defp entity(context, :account) do
    %Bank.Account{
      name: Faker.Name.name(),
      user: get_assoc(context, :user)
    }
  end

  # Convenience API

  @doc """
  Builds an entity with fake data in memory. It is NOT persisted to DB (use insert for that).

  Optionally, you can pass a `context` map and an `attributes` map/keyword list as extra
  arguments.

  The context can be used in the entity functions to enforce specific rules or associations.

  Attributes are used to override parameters with custom data.

  Returns a struct.
  """

  def build(factory), do: build(factory, %{}, [])
  def build(factory, context: %{} = context), do: build(factory, context, [])
  def build(factory, attributes), do: build(factory, %{}, attributes)

  def build(factory, context, attributes) when is_atom(factory) and is_map(context) do
    context |> entity(factory) |> filter_overridden(attributes) |> struct(attributes)
  end

  @doc """
  Builds an entity with fake data and persists it to database.

  Refer to `build/1` for optional arguments.

  Returns a struct.
  """
  def insert(factory), do: insert(factory, %{}, [])
  def insert(factory, context: %{} = context), do: insert(factory, context, [])
  def insert(factory, attributes), do: insert(factory, %{}, attributes)

  def insert(factory, context, attributes) when is_atom(factory) and is_map(context) do
    Repo.insert!(build(factory, context, attributes))
  end

  @doc """
  Same as `build/1`, except it generates raw maps of attributes, even for nested structs.

  This allows generation of attribute maps to test domain calls. (structs cannot be passed to
  changesets)

  Returns a map.
  """
  def attrs(factory), do: attrs(factory, %{}, [])
  @spec attrs(:account | :transaction, maybe_improper_list) :: map
  def attrs(factory, context: %{} = context), do: attrs(factory, context, [])
  def attrs(factory, attributes) when is_list(attributes), do: attrs(factory, %{}, attributes)
  @spec attrs(:account | :transaction, map, any) :: map
  def attrs(factory, context, attributes) when is_atom(factory) and is_map(context) do
    factory |> build(context) |> recursive_struct_to_map() |> Map.merge(Map.new(attributes))
  end

  @doc """
  Builds an empty context map

  Returns a map.
  """
  def new_context, do: %{}

  @doc """
  Updates a context map by constructing an entity specified by factory. It is stored as a
  key-value pair where the key is the same atom as `factory` and the value is the struct
  itself.

  Attributes can also be overridden just like in `build/1`.

  Returns a map.
  """
  def compose(context, factory, attributes \\ []) when is_atom(factory) do
    context |> Map.put(factory, insert(factory, context, attributes))
  end

  #
  # Gets the corresponding entity in context from the atom received or build it up in
  # case its not there, from the factory specification
  #
  defp get_assoc(context, entity_atom_or_list, attributes \\ []) when is_map(context) do
    entity_list = List.wrap(entity_atom_or_list)

    case Enum.find_value(entity_list, nil, fn entity_atom -> context[entity_atom] end) do
      nil -> entity_list |> List.first() |> build(context, attributes)
      entity -> entity
    end
  end

  #
  # Entities build nested sub-entities by default.
  # However, the developer may override some of these sub-entities by setting
  # an association via foreign key. This function discards the pre-generated
  # entities in case an override is set.
  #
  # e.g.: Drop a generated 'patient' if an explicit 'patient_id' was passed
  #
  defp filter_overridden(entity, attributes) do
    to_drop =
      Enum.reduce(attributes, [], fn {identifier, _value}, acc ->
        string_identifier = "#{identifier}"

        with true <- String.ends_with?(string_identifier, "_id"),
             raw <-
               string_identifier
               |> String.replace_suffix("_id", "")
               |> String.to_atom(),
             true <- Map.has_key?(entity, raw) do
          [raw | acc]
        else
          _ -> acc
        end
      end)

    Map.drop(entity, to_drop)
  end
end
