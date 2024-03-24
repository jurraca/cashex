defmodule Cashu.Mint do
    @moduledoc """
    NUT-04: mint quotes and requests. Minting means "exchanging an asset for ecash".
    """
    defmodule QuoteRequest do
        @moduledoc """
        Mint Quote Request: the wallet requests an invoice to pay in order to receive ecash.
        The unit specifies the unit that denominates the amount.
        The path of the request will indicate the invoice method, for example, bolt11 for Lightning Bolt11 invoices.
        """
        defstruct [:amount, :unit]

        @type t :: %{
            amount: pos_integer(),
            unit: String.t()
        }

        alias Cashu.Parser

        @spec new(pos_integer(), String.t()) :: t()
        def new(amount, unit \\ "sat") when is_integer(amount) do
            %__MODULE__{amount: amount, unit: unit}
        end

        def parse(resp), do: Parser.parse_response(resp, %__MODULE__{})
    end

    defmodule QuoteResponse do
        @moduledoc """
        The mint responds with a `QuoteResponse`. The `quote` field is a unique ID used for internal payment state. It MUST NOT be derivable from the payment `request`.
        For a Lightning BOLT11 payment, the request will be a BOLT11 invoice.
        """
        defstruct [:quote, :request, :paid, :expiry]

        @type t :: %{
            quote: String.t(),
            request: String.t(),
            paid: boolean(),
            expiry: pos_integer()
        }

        alias Cashu.Parser

        def new(quote_id, request, paid, expiry) do
            %__MODULE__{
                quote: quote_id,
                request: request,
                paid: paid,
                expiry: expiry
            }
        end

        def parse(resp), do: Parser.parse_response(resp, %__MODULE__{})
    end

    defmodule Request do
        @moduledoc """
        Once the wallet has paid the invoice in the `request` field of `QuoteResponse`, it provides an array of `BlindedMessage` which sum to the amount requested in the quote, along with the `quote` ID.
        """
        defstruct [:quote, :outputs]

        alias Cashu.{BlindedMessage, Parser}

        @type t :: %{
            quote: String.t(),
            outputs: [BlindedMessage.t()]
        }

        def new(quote_id, outputs) when is_list(outputs) do
            %__MODULE__{
                quote: quote_id,
                outputs: outputs
            }
        end

        def parse(resp), do: Parser.parse_response(resp, %__MODULE__{})
    end

    defmodule Response do
        @moduledoc """
        In response to a `Mint.Request`, the mint signs each `BlindedMessage` provided, and returns an array of `BlindedSignature`.
        Upon receiving these, the wallet will unblind these signatures, and store those as `Proofs` in their database.
        """
        defstruct [:signatures]

        alias Cashu.{BlindedSignature, Parser}

        @type t :: %{
            signatures: [BlindedSignature.t()]
        }

        def new(signatures) when is_list(signatures) do
            %__MODULE__{
                signatures: signatures
            }
        end

        def parse(resp), do: Parser.parse_response(resp, %__MODULE__{})
    end
end