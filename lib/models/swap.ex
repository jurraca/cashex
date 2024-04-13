defmodule Cashu.Swap do
  alias Cashu.{BlindedMessage, BlindedSignature, Proof}

  defmodule Request do
    @moduledoc """
    Request swap tokens
    """
    defstruct [:inputs, :outputs]

    @type t :: %{
      inputs: [Proofs.t()],
      outputs: [BlindedMessage.t()]
    }

    def new(inputs, outputs) do
      %__MODULE__{
        inputs: inputs,
        outputs: outputs
      }
    end

    def validate(%{inputs: inputs, outputs: outputs} = swap_req) do
      with %{errors: []} <- Proof.validate_proof_list(inputs),
           %{errors: []} <- BlindedMessage.validate_bm_list(outputs) do
        {:ok, swap_req}
      end
    end
  end

  defmodule Response do
    @moduledoc """
    Swap Response: mint responds with blind signatures on the previously provided tokens.
    """
    defstruct [:signatures]

    alias Cashu.BlindedSignature
    @type t :: %{signatures: [BlindedSignature.t()]}

    def new(signatures) do
      %__MODULE__{
        signatures: signatures
      }
    end

    def validate(%{signatures: sigs}) do
      BlindedSignature.validate_sig_list(sigs)
    end
  end
end
