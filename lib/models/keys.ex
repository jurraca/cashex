defmodule Cashu.Keyset do
  @moduledoc """
  NUT-01: public keys which the mint will sign new outputs with.
  The `get_keys_response/1` function should be used to return the *active* keysets
  via the `/v1/keys` endpoint to the user.
  """
  alias Cashu.{Error, Validator}

  @derive Jason.Encoder
  defstruct [:id, :unit, :keys]

  @keyset_version "00"

  @type mint_pubkeys() :: %{
          required(pos_integer()) => String.t()
        }

  @type t :: %__MODULE__{
          id: String.t(),
          unit: String.t(),
          keys: mint_pubkeys()
        }

  @spec new(Map.t(), String.t()) :: t()
  def new(keys, unit) when is_map(keys) do
    %__MODULE__{
      id: derive_keyset_id(keys),
      unit: unit,
      keys: keys
    }
  end

  @spec get_keys_response(t()) :: String.t()
  def get_keys_response(keysets) do
    %{keysets: keysets} |> Jason.encode()
  end

  @spec get_mint_pubkeys() :: t()
  def get_mint_pubkeys() do
    Application.get_env(:cashu, :pubkeys)
  end

  @spec get_supported_units() :: [Integer.t()]
  def get_supported_units() do
    get_mint_pubkeys() |> Map.keys()
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

  def valid_id?(%__MODULE__{id: id, keys: keys}) do
    id == derive_keyset_id(keys)
  end

  def validate(%{id: id, unit: unit, active: active} = keyset) do
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
