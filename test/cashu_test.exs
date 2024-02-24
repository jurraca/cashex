defmodule CashuTest do
  use ExUnit.Case

  alias Cashu.Token

  describe "" do
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

    test "create a new token", %{token: token} do
      tokens_list = token.token
      unit = token.unit
      memo = token.memo

      new_token = Token.new(tokens_list, unit, memo)

      assert new_token == token
    end

    test "serializes token into base64_urlsafe string", %{
      serialized_token: serialized_token,
      token: token
    } do
      {:ok, serialized} = Token.serialize(token)
      assert serialized == serialized_token
    end

    test "deserializes base64_urlsafe string into token", %{
      serialized_token: serialized_token,
      token: token
    } do
      {:ok, deserialized} = Token.deserialize(serialized_token)
      assert deserialized == token
    end

    ## test errors when creating new token
    ## test error return invalid proofs, single and multiple
    ## test jason decode failure handling
  end

  describe "Error handling" do
    test "returns an error struct when an error occurs" do
      error_detail = "oops"
      #error_code = 1337

      assert Cashu.Error.new(error_detail) == {:error, %Cashu.Error{
               detail: "oops",
               code: 0
             }
            }
    end
  end
end