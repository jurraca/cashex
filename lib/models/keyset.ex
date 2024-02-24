defmodule Cashu.Keyset do
  @moduledoc """
  NUT-02: return all keysets.
  This should return all keysets, active or not, via the `v1/keysets` endpoint
  """
  @derive Jason.Encoder
  defstruct [:id, :unit, :active]

  @type keyset() :: %{
          id: String.t(),
          unit: String.t(),
          active: boolean()
        }

  alias Bitcoinex.Secp256k1.Point

  @keyset_version "00"

  def derive_keyset_id(keys) when is_map(keys) do
    pubkey_concat =
      keys
      |> Map.values()
      |> Enum.join()

    id =
      :crypto.hash(:sha256, pubkey_concat)
      |> Base.encode16(case: :lower)
      |> String.slice(0..14)

    @keyset_version <> id
  end

  def validate(%__MODULE__{id: id, unit: unit, active: active}) do
  end
end
