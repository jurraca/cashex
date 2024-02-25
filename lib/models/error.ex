defmodule Cashu.Error do
  @moduledoc """
  The Cashu error interface. Code meanings tbd.
  """

  defstruct [:detail, :code]
  @typedoc "A Cashu error response"
  @type t() :: %__MODULE__{
          detail: String.t(),
          code: non_neg_integer()
        }

  @spec new(String.t()) :: t()
  def new(reason) when is_binary(reason) do
    # get_error_code(error)
    {:error, %__MODULE__{detail: reason, code: 0}}
  end

  # a generic case to passthrough the ok result and create the error.
  def check(result) do
    case result do
      # passthru ok result
      {:ok, _} = ok -> ok
      {:error, reason} -> new(reason)
    end
  end
end
