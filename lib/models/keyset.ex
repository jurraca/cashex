defmodule Cashu.Keyset do
  defstruct [:id, :unit, :active]

  alias Bitcoinex.Secp256k1.Point
  alias Cashu.Repo

  @units [1, 2, 4, 8, 16, 32, 64]
  @keyset_version "00"

  def derive_keyset_id(keys) when is_map(keys) do
    pubkey_concat =
      keys
      |> Map.values()
      |> Enum.map(&Point.serialize_public_key(&1))
      |> Enum.join()

    @keyset_version <> :crypto.hash(:sha256, pubkey_concat)
  end

  def validate(%__MODULE__{id: id, unit: unit, active: active}) do
  end
end
