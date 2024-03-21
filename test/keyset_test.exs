defmodule KeysetTest do
  use ExUnit.Case

  alias Cashu.{BDHKE, Keys, Keyset}
  alias Bitcoinex.Secp256k1.{Point, PrivateKey}

  setup do
    units = [1, 2, 4, 8] |> Enum.map(&Integer.to_string/1)
    keys = Enum.reduce(units, %{}, fn unit, acc ->
      {:ok, privkey} = BDHKE.random_number() |> PrivateKey.new()
        pubkey = privkey |> PrivateKey.to_point() |> Point.serialize_public_key()
        Map.put(acc, unit, pubkey)
    end)
    {:ok, %{keys: keys}}
  end

  test "generate a keyset ID from a set of keys", %{keys: keys} do
    id = Keyset.derive_keyset_id(keys)
    assert Keyset.valid_id?(%Keyset{id: id, unit: "sat", keys: keys})
  end
end