defmodule Cashu.Validator do
  @moduledoc """
  Validator functions for cashu data fields.

  All functions in this module should return an :ok or :error tuple.
  Cashu.Error return values are constructed upstream, usually from these error values.
  """

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

  def validate_unit("sat"), do: {:ok, "sat"}
  def validate_unit(_), do: {:error, "Invalid currency unit: sats only bb"}

  def validate_memo(memo) when is_binary(memo), do: {:ok, memo}
  def validate_memo(_), do: {:error, "Invalid memo: not a string"}

  def validate_url(mint_url) do
    case URI.parse(mint_url) do
      %URI{host: nil} -> {:error, "invalid mint URL"}
      %URI{scheme: "https", host: host} -> {:ok, host}
      %URI{scheme: nil} -> {:error, "no http scheme provided"}
      _ -> {:error, "could not parse mint URL"}
    end
  end

  def validate_keyset_id("00" <> keyset_id) do
    case String.length(keyset_id) == 14 do
      true -> {:ok, keyset_id}
      false -> {:error, "Invalid keyset ID length, got: #{keyset_id}"}
    end
  end

  def validate_keyset_id(keyset_id), do: {:error, "Invalid Keyset ID version prefix, got: #{keyset_id}"}

  @doc """
  Validate a list of structs and collect the results into a map of ok/error tuples.
  We do this often in Cashu: validate a list of Proofs, a list of BlindedSignatures, Tokens, etc.
  We usually want to reject the whole set if an error occurs in one of them.
  """
  def validate_list(list, validate_fun, acc \\ %{ok: [], error: []})
  def validate_list([], _validate_fun, %{ok: ok_proofs, error: []}), do: {:ok, ok_proofs}
  def validate_list([], _validate_fun, %{ok: _, error: errors}), do: {:error, errors}

  def validate_list([head | tail], validate_fun, acc) do
    new_acc = validate_fun.(head) |> collect_results(acc)
    validate_list(tail, new_acc)
  end

  # an accumulator map with :ok and :error keys and a list as values
  def collect_results({key, value}, acc) do
    acc_val = Map.get(acc, key)
    new_list = [value | acc_val]
    Map.put(acc, key, new_list)
  end

  @doc """
  take a string key map, and a target struct, and try to add its values to the matching struct fields.
  Only operates on top level keys.
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
