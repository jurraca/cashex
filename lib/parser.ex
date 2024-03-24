defmodule Cashu.Parser do

  @doc """
  Parse an incoming API response, and attempt to decode it, and return its internal struct representation.
  """
  def parse_response(resp, struct) when is_binary(resp) do
    case Jason.decode(resp) do
      {:ok, decoded} -> map_string_to_atom(decoded, struct)
      {:error, reason} -> Cashu.Error.new(reason)
    end
  end

  def parse_response(_resp, _struct), do: Cashu.Error.new("response was not a binary.")

  @doc """
  Take a string key map, and a target struct, and try to add its values to the matching struct fields.
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