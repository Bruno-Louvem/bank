defmodule Banking.Utils do
  @moduledoc """
  Utility functions.
  """

  @doc """
  Recursively transforms a struct and its nested structs into maps.
  Preserves structs outside of the "Banking.*" namespace (such as DateTime).
  """
  def recursive_struct_to_map(%{__struct__: type} = struct) do
    base_namespace = type |> Module.split() |> List.first()

    case base_namespace do
      "Banking" -> struct |> Map.from_struct() |> recursive_struct_to_map()
      _ -> struct
    end
  end

  def recursive_struct_to_map(%{} = map),
    do: map |> Enum.map(fn {k, v} -> {k, recursive_struct_to_map(v)} end) |> Map.new()

  def recursive_struct_to_map(list) when is_list(list),
    do: Enum.map(list, fn v -> recursive_struct_to_map(v) end)

  def recursive_struct_to_map(primitive), do: primitive
end
