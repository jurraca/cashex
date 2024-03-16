defmodule Cashu.Keys do
  @moduledoc """
  NUT-01: public keys which the mint will sign new outputs with.
  The `get_keys_response/1` function should be used to return the *active* keysets
  via the `/v1/keys` endpoint to the user.
  """

  @derive Jason.Encoder
  defstruct [:id, :unit, :keys]

  alias Cashu.Keyset

  @type mint_pubkeys() :: %{
          required(pos_integer()) => String.t()
        }

  @type t :: %__MODULE__{
          id: String.t(),
          unit: String.t(),
          keys: mint_pubkeys()
        }

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

  def valid_id?(%__MODULE__{id: id, keys: keys}) do
    id == Keyset.derive_keyset_id(keys)
  end
end
