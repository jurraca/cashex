defmodule Cashu.BDHKE do
  @moduledoc """
  An implementation of Blind Diffie Hellman Key Exchange according to the Cashu spec.
  """
  alias Bitcoinex.Secp256k1
  alias Bitcoinex.Secp256k1.{Math, Params, Point, PrivateKey}

  @n Params.curve().n

  @max_privkey @n - 1

  @doc """
  Map a hash to the Secp256k1 elliptic curve.
  """
  def hash_to_curve(msg) do
    hash = sha256_hash(msg)
    x = "02" <> Base.encode16(hash, case: :lower)
    iterate_to_valid_point(x)
  end

  defp iterate_to_valid_point(x) do
    case Secp256k1.get_y(x, false) do
      {:error, "invalid sq root"} ->
        iterate_to_valid_point(sha256_hash(x))

      {:ok, y} ->
        {:ok, %Point{x: :binary.decode_unsigned(x), y: y}}
    end
  end

  @doc """
  In the first step of the exchange, Alice has a secret message, and a secret number to blind this message.
  If the number (the "blinding factor") doesn't exist we create it.
  She provides Bob with a blinded point.
  """
  def blind_point(secret_msg) do
    {:ok, blinding_factor} = random_number() |> PrivateKey.new()
    blind_point(secret_msg, blinding_factor)
  end

  def blind_point(secret_msg, blinding_factor) do
    {:ok, point} = hash_to_curve(secret_msg)
    blinding_point = PrivateKey.to_point(blinding_factor)
    blinded_point = Math.add(point, blinding_point)
    {:ok, blinded_point, blinding_factor.d}
  end

  @doc """
  In step 2, Bob (the mint) uses this blinded point, and his private key "a",
  to sign this blinded point. Effectively "committing" to this blinded point.
  He returns this signature-on-blinded-point "c_" .
  """
  def sign_blinded_point(b_point, a_privkey) do
    c_ = Math.multiply(b_point, a_privkey.d)

    {:ok, e, s} = mint_create_dleq(b_point, a_privkey)

    {:ok, c_, e, s}
  end

  @doc """
    In step 3, Alice takes this signed commitment "c_", Bob's public key "a_point",
    and her blinding factor from step 1.
    By substracting her blinding factor from c_ , she "unblinds" the signature on her secret message.
    This is your ecash token.
  """
  def generate_proof(c_, r, a_point) do
    case a_point
         |> Math.multiply(r)
         |> negate() do
      {:ok, a_negated} -> {:ok, Math.add(c_, a_negated)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
    A discrete log equality proof (DLEQ)

     r = random nonce
    R1 = r*G
    R2 = r*B'
     e = hash(R1,R2,A,C')
     s = r + e*a
  """
  def mint_create_dleq(b_point, a_privkey) do
    # Generate a random PrivateKey p for the nonce
    {:ok, p_priv} = random_number() |> PrivateKey.new()
    mint_create_dleq(b_point, a_privkey, p_priv)
  end

  def mint_create_dleq(b_point, a_privkey, p_priv) do
    r1 = PrivateKey.to_point(p_priv)
    r2 = Math.multiply(b_point, p_priv.d)

    a_point = PrivateKey.to_point(a_privkey)
    c_ = Math.multiply(b_point, a_privkey.d)

    e = hash_pubkeys([r1, r2, a_point, c_]) |> :binary.decode_unsigned()

    # scalar multiplication and addition here, therefore modulo the curve order.
    multiplied = Math.modulo(a_privkey.d * e, @n)
    s = Math.modulo(p_priv.d + multiplied, @n)

    {:ok, e, s}
  end

  @doc """
  To verify the DLEQ, Alice recreates r1 and r2 from e,s provided by Bob.
  """
  def verify_dleq(b_, c_, e, s, a_point) do
    {:ok, a_negated} = a_point |> Math.multiply(e) |> negate()
    r1 = s |> PrivateKey.to_point() |> Math.add(a_negated)
    {:ok, c_negated} = c_ |> Math.multiply(e) |> negate()
    r2 = b_ |> Math.multiply(s) |> Math.add(c_negated)

    hash_k = [r1, r2, a_point, c_] |> hash_pubkeys() |> :binary.decode_unsigned()
    e == hash_k
  end

  @doc """
  To verify that the user/client (Alice) has the right message, the mint (Bob) takes the unblinded sig from Alice,
  and the original secret message, and checks it against their private key.
  If multiplying the message hashed to curve by Bob's private key is equal to the unblinded signature,
  then the user's unblinded signature is valid for the message.
  """
  def is_valid?(a_privkey, c, msg) do
    {:ok, y} = hash_to_curve(msg)
    c == Math.multiply(y, a_privkey.d)
  end

  def sha256_hash(msg), do: :crypto.hash(:sha256, msg)

  def random_number(), do: :rand.uniform(@max_privkey)

  def negate(point_a) do
    pubkey = Point.serialize_public_key(point_a)

    case negate_hex(pubkey) do
      {:ok, a_negated} -> Point.parse_public_key(a_negated)
      {:error, reason} -> raise(reason)
    end
  end

  def negate_hex("02" <> rest), do: {:ok, "03" <> rest}
  def negate_hex("03" <> rest), do: {:ok, "02" <> rest}
  def negate_hex(pubkey), do: {:error, "pubkey prefix did not match 02 or 03, got #{pubkey}"}

  def hash_pubkeys(pubkeys) when is_list(pubkeys) do
    pubkeys
    |> Enum.map(&Point.serialize_public_key(&1))
    |> Enum.join()
    |> sha256_hash()
  end
end
