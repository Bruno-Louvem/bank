defmodule Banking.UtilsTest do
  use ExUnit.Case

  import Banking.Utils, only: [recursive_struct_to_map: 1]

  alias Banking.Bank.Account

  test "recursive struct handler" do
    struct = simulate_changeset_error()
    assert struct == struct |> recursive_struct_to_map

    errors = struct.errors
    assert errors == struct.errors |> recursive_struct_to_map

    data = struct.data
    assert data != struct.data |> recursive_struct_to_map
  end

  def simulate_changeset_error do
    %Account{}
    |> Account.changeset(%{})
  end
end
