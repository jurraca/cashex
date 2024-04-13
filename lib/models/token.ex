defmodule Cashu.Token do
  @moduledoc """
    Create and decode tokens.
    Format: cashu[version][base64_token_json]
  """
  alias Cashu.{Error, BaseParser, Proof, Serde, Validator}
  import Validator
  require Logger

  @behaviour Serde

  @derive Jason.Encoder
  defstruct [:token, :unit, :memo]

  @type t :: %__MODULE__{
          token: [%{mint: String.t(), proofs: [Proof.t()]}],
          unit: String.t() | nil,
          memo: String.t() | nil
        }

  @doc """
  Create a new Cashu.Token struct from a list of Proofs, a unit, and optional memo.
  """
  def new(tokens_list, unit, memo \\ "") when is_list(tokens_list) and is_binary(unit) do
    %__MODULE__{
      token: tokens_list,
      unit: unit,
      memo: memo
    }
  end

  def new(%{"token" => tokens_list, "unit" => unit, "memo" => memo}) do
    new(tokens_list, unit, memo)
  end

  @impl Serde
  def serialize(token, version \\ "A")
  def serialize(%__MODULE__{} = token, version) do
    case Jason.encode(token) do
      {:ok, encoded} ->
        serialized = Base.url_encode64(encoded, padding: false)
        {:ok, "cashu" <> version <> serialized}

      {:error, reason} ->
        Error.new(reason)
    end
  end

  def serialize(_, _), do: {:error, :invalid_token}

  @impl Serde
  def deserialize(<<"cashu", version::binary-size(1), token::binary>>) do
    if(version != "A", do: Logger.info("Got cashu token version #{version}"))

    case Base.url_decode64(token, padding: false) do
      {:ok, json} -> Jason.decode!(json) |> parse_nested()
      :error -> Error.new("could not decode token from binary #{token}")
    end
  end

  def deserialize(_), do: {:error, "Invalid binary"}

  @doc """
  Takes a cashu token struct with string keys, the default behavior when deserializing JSON,
  and returns a valid Cashu.Token struct.
  """
  def parse_nested(binary) when is_binary(binary) do
    case BaseParser.deserialize(binary) do
      {:ok, %__MODULE__{} = tk} -> parse_nested(tk)
    end
  end

  def parse_nested(%{"token" => token, "unit" => unit, "memo" => memo}) do
    tokens =
      Enum.reduce(token, [], fn proofs, acc ->
        proofs_atoms = proofs_to_struct(proofs)
        new = Map.new(proofs: proofs_atoms, mint: proofs["mint"])
        [new | acc]
      end)

    {:ok, struct(__MODULE__, token: tokens, unit: unit, memo: memo)}
  end

  def proofs_to_struct(%{"proofs" => proofs}) do
    Enum.map(proofs, fn p -> BaseParser.string_map_to_struct(p, %Proof{}) end)
  end

  @doc """
  Validate a token's content.
  """
  #@impl Serde
  def validate(%__MODULE__{token: token_list, unit: unit, memo: memo} = token) do
    with {:ok, _valid_proofs} <- validate_token_list(token_list),
         {:ok, _} <- validate_unit(unit),
         {:ok, _} <- validate_memo(memo) do
      {:ok, token}
    else
      {:error, error} -> if(is_list(error), do: handle_errors(error), else: Error.new(error))
      err -> err
    end
  end

  def validate({:error, _} = err), do: err
  def validate(_), do: {:error, "Invalid token provided"}

  def handle_errors(errors) do
    if Enum.count(errors) > 1 do
      Enum.map(errors, fn err -> Logger.error(err) end)
      {:error, "Multiple proof validation errors received, see logs."}
    else
      Logger.error(errors)
      {:error, Enum.at(errors, 0)}
    end
  end

  @spec validate_token_list(List.t()) :: {:ok, List.t()} | {:error, List.t()}
  def validate_token_list(tokens) do
    Enum.map(tokens, fn items ->
      %{mint: mint_url, proofs: proofs} = items

      case validate_url(mint_url) do
        {:error, _} = err -> err
        {:ok, _} -> Proof.validate_proof_list(proofs)
      end
    end)
    |> collect_token_validations()
  end

  defp collect_token_validations(list, acc \\ %{ok: [], error: []})
  defp collect_token_validations([], %{ok: ok_proofs, error: []}), do: {:ok, ok_proofs}
  defp collect_token_validations([], %{ok: _, error: errors}), do: {:error, errors}

  defp collect_token_validations([head | tail], acc) do
    new_acc = Validator.collect_results(head, acc)
    collect_token_validations(tail, new_acc)
  end
end
