defmodule Cashu.Serde do
  # interfaces that each module should implement
  @callback serialize(Map.t()) :: {:ok, binary()} | {:error, binary()}
  @callback deserialize(binary()) :: {:ok, Map.t()} | {:error, binary()}
  #@callback validate(Map.t()) :: {:ok, Map.t()} | {:error, Map.t()}
end
