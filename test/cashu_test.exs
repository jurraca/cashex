defmodule CashuTest do
  use ExUnit.Case

  alias Cashu.Token

  describe "Token " do
    setup do
      serialized_token =
        "cashuAeyJtZW1vIjoiVGhhbmsgeW91IiwidG9rZW4iOlt7Im1pbnQiOiJodHRwczovL2Nvb2wtbWludC5uZXQiLCJwcm9vZnMiOlt7IkMiOiIwMmJjOTA5Nzk5N2Q4MWFmYjJjYzczNDZiNWU0MzQ1YTkzNDZiZDJhNTA2ZWI3OTU4NTk4YTcyZjBjZjg1MTYzZWEiLCJhbW91bnQiOjIsImlkIjoiMDA5YTFmMjkzMjUzZTQxZSIsInNlY3JldCI6IjQwNzkxNWJjMjEyYmU2MWE3N2UzZTZkMmFlYjRjNzI3OTgwYmRhNTFjZDA2YTZhZmMyOWUyODYxNzY4YTc4MzcifV19XSwidW5pdCI6InNhdCJ9"

      token = %Token{
        token: [
          %{
            mint: "https://cool-mint.net",
            proofs: [
              %Cashu.Proof{
                amount: 2,
                id: "009a1f293253e41e",
                secret: "407915bc212be61a77e3e6d2aeb4c727980bda51cd06a6afc29e2861768a7837",
                C: "02bc9097997d81afb2cc7346b5e4345a9346bd2a506eb7958598a72f0cf85163ea"
              }
            ]
          }
        ],
        unit: "sat",
        memo: "Thank you"
      }

      {:ok, %{token: token, serialized_token: serialized_token}}
    end

    test "created successfully", %{token: token} do
      tokens_list = token.token
      unit = token.unit
      memo = token.memo

      new_token = Token.new(tokens_list, unit, memo)

      assert new_token == token
    end

    test "fails with invalid fields", %{token: %{token: token_list}} do
      assert_raise FunctionClauseError, fn ->
        raise Token.new(token_list, :not_a_binary_unit)
      end

      assert_raise FunctionClauseError, fn ->
        raise Token.new("not a list", "correctly binary")
      end
    end

    test "serializes into base64_urlsafe string", %{
      serialized_token: serialized_token,
      token: token
    } do
      {:ok, serialized} = Token.serialize(token)
      assert serialized == serialized_token
    end

    test "returns error on failed serialization" do
      assert {:error, :invalid_token} = Token.serialize(:not_a_token)
      assert {:error, %Cashu.Error{}} = Token.serialize(%Token{unit: <<123123>>})
    end

    test "deserializes base64_urlsafe string into token", %{
      serialized_token: serialized_token,
      token: token
    } do
      {:ok, deserialized} = Token.deserialize(serialized_token)
      assert deserialized == token
    end

    ## test error return invalid proofs, single and multiple
  end

  describe "Error handling" do
    test "returns a Cashu error struct when an error occurs" do
      error_detail = "oops"
      #error_code = 1337

      assert Cashu.Error.new(error_detail) == {:error, %Cashu.Error{
               detail: "oops",
               code: 0
             }
            }
    end

    test "returns a Jason Error code when Jason.encode/1 fails" do
      assert {:error, %Cashu.Error{code: 2}} = Token.serialize(%Token{unit: <<123123>>})
    end
  end
end