defmodule Cashu.BaseParser do

  @doc """
  Default serialize to JSON.
  """
  def serialize(data) when is_map(data), do: Jason.encode(data)

  @doc """
  Parse an incoming API response, and attempt to decode it, and return its internal struct representation.
  """
  def deserialize(resp, struct) when is_binary(resp) do
    case Jason.decode(resp) do
      {:ok, decoded} -> string_map_to_struct(decoded, struct)
      {:error, reason} -> Cashu.Error.new(reason)
    end
  end

  def deserialize(_resp, _struct), do: Cashu.Error.new("response was not a binary.")

  def deserialize(resp) when is_binary(resp), do: Jason.decode(resp)

  @doc """
  Take a string key map, and a target struct, and try to add its values to the matching struct fields.
  Only operates on top level keys.
  """
  def string_map_to_struct(source_map, target_struct) do
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