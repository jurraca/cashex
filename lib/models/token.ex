defmodule Cashu.Token do
  @moduledoc """
    cashu[version][base64_token_json]
  """
  alias Cashu.{Error, Proof, Validator}
  require Logger

  @derive Jason.Encoder
  defstruct [:token, :unit, :memo]

  @type token() :: %{
    token: [ %{ mint: String.t(), proofs: [Proof.t]}],
    unit: String.t() | nil,
    memo: String.t() | nil
  }

  def serialize(token, version \\ "A") do
      case encode(token) do
      {:ok, encoded} ->
        serialized = Base.url_encode64(encoded, padding: false)
        {:ok, "cashu" <> version <> serialized}
      {:error, err} -> Error.new(err)
      end
  end

  def encode(%{token: token_list, unit: unit, memo: memo} = token) do
    with true <- Validator.validate_tokens_list(token_list),
         true <- Validator.is_valid_unit?(unit),
         true <- Validator.is_valid_memo?(memo) do
      Jason.encode(token) |> Error.check()
    else
      false -> {:error, "validation error on given Token"}
      errors -> handle_errors(errors)
    end
  end

  def decode(<<"cashu", version::binary-size(1), token::binary>>) do
    Logger.info("Got cashu token version #{version}")
    case Base.url_decode64(token, padding: false) do
      {:ok, json} -> Jason.decode(json)
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
    else
      Logger.error("Unknown error")
      {:error, nil}
    end
  end
end
