defmodule Cashu.Melt do
    @moduledoc """
    NUT-05: Melt quotes and requests. Melting means "redeeming ecash for another asset".
    """
    defmodule QuoteRequest do
        @moduledoc """
        The wallet holds ecash, and wants to exchange it another value, for example bitcoin.
        In this case, the `QuoteRequest` provides a BOLT11 invoice, and `["sat"]` as the unit.
        """
        defstruct [:request, :unit]

        @type t :: %{
            request: String.t(),
            unit: String.t()
        }

        alias Cashu.Parser

        def new(request, unit) when is_binary(unit) do
            %__MODULE__{
                request: request,
                unit: unit
            }
        end

        def parse(resp), do: Parser.parse_response(resp, %__MODULE__{})
    end

    defmodule QuoteResponse do
        @moduledoc """
        The mint responds to a `QuoteRequest` with a response that specifies the minimum `amount` it is willing to redeem, a Lightning `fee_reserve` (see spec) and quote metadata.
        """
        defstruct [:quote, :amount, :fee_reserve, :paid, :expiry]

        @type t :: %{
            quote: String.t(),
            amount: pos_integer(),
            fee_reserve: pos_integer(),
            paid: boolean(),
            expiry: pos_integer()
        }

        alias Cashu.Parser

        def new(quote_id, amount, fee_reserve, paid, expiry) do
            %__MODULE__{
                quote: quote_id,
                amount: amount,
                fee_reserve: fee_reserve,
                paid: paid,
                expiry: expiry
            }
        end

        def parse(resp), do: Parser.parse_response(resp, %__MODULE__{})
    end

    defmodule Request do
        @moduledoc """
        Once the wallet receives a `QuoteResponse` from the mint, it can provide `Proofs` and the quote ID, effectively sending ecash to the mint.
        """
        defstruct [:quote, :inputs]

        alias Cashu.{Parser, Proof}

        @type t :: %{
            quote: String.t(),
            inputs: [Proof]
        }

        def new(quote_id, inputs) when is_list(inputs) do
            %__MODULE__{
                quote: quote_id,
                inputs: inputs
            }
        end

        def parse(resp), do: Parser.parse_response(resp, %__MODULE__{})
    end

    defmodule Response do
        @moduledoc """
        Once the mint receives a `Request` from the wallet with `Proofs`, the mint pays the invoice provided in the `QuoteRequest`, and returns the `payment_preimage` (the proof of payment, in the case of a BOLT11 payment).
        Once the wallet receives a `paid = true` response, it should remove those inputs from its database, as they can no longer be used for payments. If `false`, it can repeat the request as many times as needed.
        """
        defstruct [:paid, :payment_preimage]

        @type t :: %{
            paid: boolean(),
            payment_preimage: String.t() | nil
        }

        alias Cashu.Parser

        def new(paid, payment_preimage) do
            %__MODULE__{
                paid: paid,
                payment_preimage: payment_preimage
            }
        end

        def parse(resp), do: Parser.parse_response(resp, %__MODULE__{})
    end
end