defmodule Cashu.MintInfo do
    @moduledoc """
    NUT-06: mint info
    """

    defstruct [:name, :pubkey, :version, :description, :description_long, :contact, :motd, :nuts]

    def mint_info_response(name, pubkey, version, description, nuts, opts \\ []) do
       %__MODULE__{
        name: name,
        pubkey: pubkey,
        version: version,
        description: description,
        description_long: Keyword.get(opts, :description_long),
        contact: Keyword.get(opts, :contact),
        motd: Keyword.get(opts, :motd),
        nuts: nuts
       }
       |> Jason.encode!
    end

    def update(%__MODULE__{} = current, new_fields) when is_map(new_fields) do
        Map.merge(current, new_fields)
    end
end