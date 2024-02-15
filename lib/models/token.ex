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

  def new(tokens_list, unit, memo \\ "") do
    with {:ok, _valid_proofs} <- Validator.validate_token_list(tokens_list),
      {:ok, _} <- Validator.is_valid_unit?(unit),
      {:ok, _} <- Validator.is_valid_memo?(memo) do
        %__MODULE__{
          token: tokens_list,
          unit: unit,
          memo: memo
        }
    else
      {:error, error} -> if(is_list(error), do: handle_errors(error), else: Error.new(error))
      err -> err
    end
  end

  def new(%{"token" => tokens_list, "unit" => unit, "memo" => memo}) do
    new(tokens_list, unit, memo)
  end

  def serialize(token, version \\ "A") do
      case encode(token) do
      {:ok, encoded} ->
        serialized = Base.url_encode64(encoded, padding: false)
        {:ok, "cashu" <> version <> serialized}
      {:error, err} -> Error.new(err)
      end
  end

  def encode(%__MODULE__{} = token) do
      Jason.encode(token) |> Error.check()
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
    if Enum.count(errors) > 1 do
      Enum.map(errors, fn err -> Logger.error(err) end)
      {:error, "Multiple proof validation errors received, see logs."}
    else
      Logger.error(errors)
      {:error, Enum.at(errors, 0)}
    end
  end
end
