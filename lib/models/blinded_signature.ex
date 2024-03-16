defmodule Cashu.BlindedSignature do
  @moduledoc """
  NUT-00: BlindedSignature
  A BlindedSignature is sent from Bob to Alice after minting tokens or after swapping tokens. A BlindedSignature is also called a promise.
  """
  alias Cashu.{BDHKE, Error, Validator}
  alias Bitcoinex.Secp256k1.Point

  @derive Jason.Encoder
  defstruct [:amount, :id, :c_]

  @type t :: %__MODULE__{
          amount: pos_integer(),
          id: String.t(),
          c_: String.t()
        }

  def new(blinded_message, mint_privkey) do
    case BDHKE.sign_blinded_point(blinded_message, mint_privkey) do
      {:ok, commitment_point, e, s} ->
        # id = get_keyset_id()
        hex_c_ = Point.serialize_public_key(commitment_point)
        %__MODULE__{amount: blinded_message.amount, id: nil, c_: hex_c_}

      {:error, reason} ->
        Error.new(reason)
    end
  end

  def validate(%__MODULE__{amount: amount, id: id, c_: c_} = sig) do
    with {:ok, _} <- Validator.validate_amount(amount),
         {:ok, _} <- Validator.validate_id(id),
         {:ok, _} <- Validator.validate_c_(c_) do
      {:ok, sig}
    else
      {:error, reason} -> Error.new(reason)
    end
  end

  def validate_sig_list(list), do: Validator.validate_list(list, &validate/1)

  def encode(%__MODULE__{} = msg) do
    case Jason.encode(msg) do
      {:ok, encoded} ->
        {:ok, encoded}

      {:error, reason} ->
        Error.new(reason)
    end
  end
end
