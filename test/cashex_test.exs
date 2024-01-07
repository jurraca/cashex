defmodule CashuTest do
  use ExUnit.Case
  doctest Cashu

  describe "Blind Diffie-Hellman key exchange" do
    test "blinding a message correctly calculates B_ given x, r, and G" do
      x = "random string"
      r = "random blinding factor"
      assert Cashu.blind_message(x, r) == expected_blinded_message
    end

    test "unblinding a signature correctly calculates C given C_ and r" do
      blinded_signature = "blinded signature"
      r = "random blinding factor"
      assert Cashu.unblind_signature(blinded_signature, r) == expected_unblinded_signature
    end
  end

  describe "Serialization" do
    test "serializes token into base64_urlsafe string" do
      token = %{}
      assert Cashu.serialize_token(token) == expected_serialized_token
    end

    test "deserializes base64_urlsafe string into token" do
      serialized_token = "base64_urlsafe serialized token"
      assert Cashu.deserialize_token(serialized_token) == expected_token_structure
    end
  end

  describe "Error handling" do
    test "returns an error struct when an error occurs" do
      error_detail = "oops"
      error_code = 1337

      assert Cashu.handle_error(error_detail, error_code) == %Cashu.Error{
               detail: "oops",
               code: 1337
             }
    end
  end
end
