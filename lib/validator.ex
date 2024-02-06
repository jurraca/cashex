defmodule Cashu.Validator do
  @moduledoc """
  Validator functions for cashu data fields.
  """

  alias Cashu.{Error, Proof}

  def validate_amount(amount) when is_integer(amount) and amount >= 0, do: {:ok, amount}
  def validate_amount(_), do: {:error, "Invalid amount"}

  def validate_id(id) when is_binary(id), do: {:ok, id}
  def validate_id(_), do: {:error, "Invalid ID"}

  def validate_b_(b_) when is_binary(b_), do: {:ok, b_}
  def validate_b_(_), do: {:error, "Invalid blinded point B_"}

  def validate_secret(secret) when is_binary(secret), do: {:ok, secret}
  def validate_secret(_), do: {:error, "Invalid secret: must be a binary"}

  def validate_c(c) when is_binary(c), do: {:ok, c}
  def validate_c(_), do: {:error, "Invalid unblinded point C"}

  def validate_c_(c_) when is_binary(c_), do: {:ok, c_}
  def validate_c_(_), do: {:error, "Invalid c_"}

  def is_valid_unit?("sat"), do: true
  def is_valid_unit?(_), do: false

  def is_valid_memo?(memo), do: is_binary(memo)

  def is_valid_url?(mint_url) do
    case URI.parse(mint_url) do
      %URI{host: nil} -> false
      %URI{scheme: "https", host: _host} -> true
      %URI{scheme: nil} -> false
    end
  end

  def validate_tokens_list(tokens) do
    tokens
    |> Enum.map(fn items ->
      %{mint: mint_url, proofs: proofs} = items

      if is_valid_url?(mint_url) do
        validate_proofs(proofs)
      else
        {:error, "Invalid mint url, got #{mint_url}"}
      end
    end)
    |> Enum.reduce([], fn
      {:ok, _}, acc -> acc
      {:error, _} = err, acc -> [err | acc]
    end)
    |> Enum.all?(fn x -> elem(x, 0) == :ok end)
  end

  def validate_proofs(list, acc \\ [])
  def validate_proofs([], acc), do: {:ok, acc}

  def validate_proofs([head | tail], acc) do
    case Proof.validate(head) do
      {:ok, %{id: proof_id}} -> validate_proofs(tail, [proof_id | acc])
      {:error, _reason} = err -> err
    end
  end

  @doc """
  take a string key map, and a target struct, and try to add its values to the matching struct fields.
  """
  def map_string_to_atom(source_map, target_struct) do
    source_keys = Map.keys(source_map)
    target_keys = Map.keys(target_struct)

    Enum.reduce(source_keys, target_struct, fn k, acc ->
      atom_key = String.to_atom(k)

      if atom_key in target_keys do
        Map.put(acc, atom_key, Map.get(source_map, k))
      else
        acc
      end
    end)
  end
end
