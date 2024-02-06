defmodule Cashu.Token do
  @moduledoc """
    cashu[version][base64_token_json]
  """
  alias Cashu.{Error, Proof, Validator}

  @derive Jason.Encoder
  defstruct [:token, :unit, :memo]

  def serialize(%__MODULE__{} = token, version \\ "A") do
    serialized =
      token
      |> encode()
      |> Base.url_encode64(padding: false)

    "cashu" <> version <> serialized
  end

  def encode(%__MODULE__{token: token_list, unit: unit, memo: memo} = token) do
    with true <- Validator.validate_tokens_list(token_list),
         true <- Validator.is_valid_unit?(unit),
         true <- Validator.is_valid_memo?(memo) do
      Jason.encode(token) |> Error.check()
    else
      errors -> handle_errors(errors)
    end
  end

  def decode(<<"cashu", version::binary-size(1), token::binary>>) do
    case Base.url_decode64(token, padding: false) do
      {:ok, json} -> json |> Jason.decode()
      :error -> Error.new("could not decode token from binary #{token}")
    end
  end

  def parse_token(map) do
    source_map = Validator.map_string_to_atom(map, %__MODULE__{})

    tokens =
      source_map
      |> Map.get(:token)
      |> Enum.reduce(%{}, fn tk, acc ->
        proofs = Map.get(tk, "proofs")

        proofs_atoms =
          Enum.map(proofs, fn p ->
            Validator.map_string_to_atom(p, %Proof{})
          end)

        acc
        |> Map.put(:mint, tk["mint"])
        |> Map.put(:proofs, proofs_atoms)
      end)

    Map.put(source_map, :token, [tokens])
  end

  def handle_errors(errors) do
    if Enum.count(errors) > 0 do
      {:error, errors}
    end
  end
end
