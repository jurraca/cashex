defmodule Cashu.BlindedMessage do
  @moduledoc """
  NUT-00: BlindedMessage
  An encrypted ("blinded") secret and an amount is sent from Alice to Bob for minting tokens or for swapping tokens. A BlindedMessage is also called an output.
  """
  alias Cashu.{BDHKE, Error, Validator}
  alias Bitcoinex.Secp256k1.Point

  @derive Jason.Encoder
  defstruct [:amount, :id, :b_]

  @type t :: %__MODULE__{
          amount: pos_integer(),
          id: String.t(),
          b_: String.t()
        }

  def new(amount, secret_message) when is_integer(amount) and is_binary(secret_message) do
    case BDHKE.blind_point(secret_message) do
      {:ok, blind_point, blinding_factor} ->
        hex_point = Point.serialize_public_key(blind_point)
        %__MODULE__{amount: amount, id: nil, b_: hex_point}

      {:error, reason} ->
        Error.new(reason)
    end
  end

  def validate(%__MODULE__{amount: amount, id: id, b_: b_} = bm) do
    with :ok <- Validator.validate_amount(amount),
         :ok <- Validator.validate_id(id),
         :ok <- Validator.validate_b_(b_) do
      {:ok, bm}
    else
      {:error, reason} -> Error.new(reason)
    end
  end

  def encode(%__MODULE__{} = msg) do
    case Jason.encode(msg) do
      {:ok, encoded} ->
        {:ok, encoded}

      {:error, reason} ->
        Error.new(reason)
    end
  end
end
