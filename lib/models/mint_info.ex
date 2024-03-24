defmodule Cashu.MintInfo do
    @moduledoc """
    NUT-06: mint info
    """

    def mint_info_response(name, pubkey, version, description, nuts, opts \\ []) do
       %{
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

end