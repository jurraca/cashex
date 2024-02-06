defmodule Cashu.Error do
  @typedoc "A Cashu error response"
  @type error() :: %__MODULE__{}

  defstruct [:detail, :code]

  @spec new(String.t()) :: error
  def new(reason) when is_binary(reason) do
    # get_error_code(error)
    {:error, %__MODULE__{detail: reason, code: 0}}
  end

  # a generic case to passthrough the ok result and handle the error.
  def check(result) do
    case result do
      # passthru ok result
      {:ok, _} = ok -> ok
      {:error, reason} -> new(reason)
    end
  end
end
