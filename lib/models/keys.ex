defmodule Cashu.Keys do
    @moduledoc """
    NUT-01: public keys which the mint will sign new outputs with.
    The `get_keys_response/1` function should be used to return the *active* keysets
    via the `/v1/keys` endpoint to the user.
    """

    @derive Jason.Encoder
    defstruct [:id, :unit, :keys]

    @type keys() :: %{
        id: String.t(),
        unit: String.t(),
        keys: Map.t()
    }

    def get_keys_response(keysets) do
        %{keysets: keysets} |> Jason.encode()
    end

    def generate_keys(units, mint_pubkeys) do
        Enum.zip(units, mint_pubkeys) |> Enum.into(%{})
    end

    def get_supported_units() do
        Application.get_env(:cashu, :units)
    end
end