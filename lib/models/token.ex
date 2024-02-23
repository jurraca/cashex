defmodule Cashu.Token do
  @moduledoc """
    Create and decode tokens.
    Format: cashu[version][base64_token_json]
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

  @doc """
  Create a new Cashu.Token struct from a list of Proofs, a unit, and optional memo.
  """
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

  def new(%{"token" => tokens_list, "unit" => unit}) do
    new(tokens_list, unit, memo)
  end

  @doc """
  Create a serialized Cashu token from a `%Token{}` struct.
  """
  def serialize(%__MODULE__{} = token, version \\ "A") do
    case encode(token) do
      {:ok, encoded} ->
        serialized = Base.url_encode64(encoded, padding: false)
        {:ok, "cashu" <> version <> serialized}
      {:error, err} -> Error.new(err)
    end
  end

  @doc """
  Deserialize a Cashu token.
  """
  def deserialize(<<"cashu", version::binary-size(1), token::binary>>) do
    if(version != "A", do: Logger.info("Got cashu token version #{version}"))
    case Base.url_decode64(token, padding: false) do
      {:ok, json} -> decode(json)
      :error -> Error.new("could not decode token from binary #{token}")
    end
  end

  @doc """
  Takes a cashu token struct with string keys, the default behavior when deserializing JSON,
  and returns a valid Cashu.Token struct.
  """
  def from_string_map(%{"token" => token, "unit" => unit, "memo" => memo}) do
    tokens = Enum.reduce(token, [], fn tk, acc ->
        proofs_atoms = tk
          |> Map.get("proofs")
          |> Enum.map(fn p ->
            Validator.map_string_to_atom(p, %Proof{})
          end)

        new = Map.new(proofs: proofs_atoms, mint: tk["mint"])
        [new | acc]
      end)

    {:ok, struct(__MODULE__, token: tokens, unit: unit, memo: memo)}
  end

  def from_string_map(_), do: {:error, "Invalid token provided"}

  def handle_errors(errors) do
    if Enum.count(errors) > 1 do
      Enum.map(errors, fn err -> Logger.error(err) end)
      {:error, "Multiple proof validation errors received, see logs."}
    else
      Logger.error(errors)
      {:error, Enum.at(errors, 0)}
    end
  end

  defp encode(%__MODULE__{} = token) do
    Jason.encode(token)
  end

  defp decode(json_str) do
    case Jason.decode(json_str) do
      {:ok, map} -> from_string_map(map)
      {:error, _} = err -> err
    end
  end
end
