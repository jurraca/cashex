defmodule Cashu.Keyset do
  @moduledoc """
  NUT-02: a keyset represents the denominations that a mint supports.
  This should return all keysets, active or not, via the `v1/keysets` endpoint
  """
  @derive Jason.Encoder
  defstruct [:id, :unit, :active]

  @type t :: %__MODULE__{
          id: String.t(),
          unit: String.t(),
          active: boolean()
        }

  alias Bitcoinex.Secp256k1.Point
  alias Cashu.{Keys, Validator}

  @keyset_version "00"

  def get_keysets_response(keysets) when is_list(keysets) do
    %{keysets: keysets} |> Jason.encode()
  end

  def derive_keyset_id(keys) when is_map(keys) do
    pubkey_concat =
      keys
      |> sort_keys()
      |> Map.values()
      |> Enum.join()

    id =
      :crypto.hash(:sha256, pubkey_concat)
      |> Base.encode16(case: :lower)
      |> String.slice(0..14)

    @keyset_version <> id
  end

  def validate(%__MODULE__{id: id, unit: unit, active: active} = keyset) do
    with true <- is_boolean(active),
         {:ok, _} <- Validator.validate_unit(unit),
         {:ok, _} <- Validator.validate_keyset_id(id) do
      {:ok, keyset}
    else
      {:error, reason} -> Error.new(reason)
    end
  end

  defp sort_keys(keys) do
    keys
    |> Enum.sort(&(String.to_integer(elem(&1, 0)) < String.to_integer(elem(&2, 0))))
    |> Enum.into(%{})
  end
end
