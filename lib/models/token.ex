defmodule Cashu.Token do
  @moduledoc """
    cashu[version][base64_token_json]
  """
  alias Cashu.{Error, Validator}
  defstruct [:token, :unit, :memo]

  def serialize(%__MODULE__{} = token, version \\ "A") do
    serialized =
      token
      |> encode()
      |> Base.url_encode64(padding: false)

    "cashu" <> version <> serialized
  end

  def encode(%__MODULE__{token: token_list, unit: unit, memo: memo} = token) do
    with true <- Validator.validate_tokens_list(token_list),
         true <- Validator.is_valid_unit?(unit),
         true <- Validator.is_valid_memo?(memo) do
      Jason.encode(token) |> Error.check()
    end
  end

  def parse(<<"cashu", version::binary-size(1), token::binary>>) do
    case Base.url_decode64(token, padding: false) do
      {:ok, json} -> Jason.decode(json)
      :error -> Error.new("could not decode token from binary #{token}")
    end
  end
end
