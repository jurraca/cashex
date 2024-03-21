defmodule Cashu.KeysetResponse do
  @moduledoc """
  NUT-02: a keyset represents the denominations that a mint supports.
  This should return all keysets, active or not, via the `v1/keysets` endpoint
  """
  @derive Jason.Encoder
  defstruct [:id, :unit, :active]

  @type t :: %__MODULE__{
          id: String.t(),
          unit: String.t(),
          active: boolean()
        }

  def get_keysets_response(keysets) when is_list(keysets) do
    %{keysets: keysets} |> Jason.encode()
  end

end
