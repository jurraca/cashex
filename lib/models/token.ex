defmodule Cashu.Token do
  @moduledoc """
    Create and decode tokens.
    Format: cashu[version][base64_token_json]
  """
  alias Cashu.{Error, Proof, Validator}
  import Validator
  require Logger

  @derive Jason.Encoder
  defstruct [:token, :unit, :memo]

  @type t() :: %{
          token: [%{mint: String.t(), proofs: [Proof.t()]}],
          unit: String.t() | nil,
          memo: String.t() | nil
        }

  @doc """
  Create a new Cashu.Token struct from a list of Proofs, a unit, and optional memo.
  """
  def new(tokens_list, unit, memo \\ "") do
    %__MODULE__{
      token: tokens_list,
      unit: unit,
      memo: memo
    }
  end

  def new(%{"token" => tokens_list, "unit" => unit, "memo" => memo}) do
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

      {:error, err} ->
        Error.new(err)
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
  Validate a token's content.
  """
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

  defp encode(%__MODULE__{} = token) do
    Jason.encode(token)
  end

  defp decode(json_str) do
    case Jason.decode(json_str) do
      {:ok, map} ->
        case from_string_map(map) do
          {:ok, token} -> validate(token)
          {:error, _} = err -> err
        end

      {:error, _} = err ->
        err
    end
  end

  @doc """
  Takes a cashu token struct with string keys, the default behavior when deserializing JSON,
  and returns a valid Cashu.Token struct.
  """
  def from_string_map(%{"token" => token, "unit" => unit, "memo" => memo}) do
    tokens =
      Enum.reduce(token, [], fn tk, acc ->
        proofs_atoms =
          tk
          |> Map.get("proofs")
          |> Enum.map(fn p ->
            Validator.map_string_to_atom(p, %Proof{})
          end)

        new = Map.new(proofs: proofs_atoms, mint: tk["mint"])
        [new | acc]
      end)

    {:ok, struct(__MODULE__, token: tokens, unit: unit, memo: memo)}
  end

  def from_string_map(err), do: {:error, "Invalid token provided"}

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
        {:ok, _} -> validate_proofs(proofs)
      end
    end)
    |> collect_token_validations()
  end

  def validate_proofs(list, acc \\ %{ok: [], error: []})
  def validate_proofs([], %{ok: ok_proofs, error: []}), do: {:ok, ok_proofs}
  def validate_proofs([], %{ok: _, error: errors}), do: {:error, errors}

  def validate_proofs([head | tail], acc) do
    new_acc =
      head
      |> Proof.validate()
      |> collect_results(acc)

    validate_proofs(tail, new_acc)
  end

  defp collect_token_validations(list, acc \\ %{ok: [], error: []})
  defp collect_token_validations([], %{ok: ok_proofs, error: []}), do: {:ok, ok_proofs}
  defp collect_token_validations([], %{ok: _, error: errors}), do: {:error, errors}

  defp collect_token_validations([head | tail], acc) do
    collect_results(head, acc)
    collect_token_validations(tail, acc)
  end

  # an accumulator map with :ok and :error keys and a list as values
  defp collect_results({key, value}, acc) do
    acc_val = Map.get(acc, key)
    new_list = [value | acc_val]
    Map.put(acc, key, new_list)
  end
end
