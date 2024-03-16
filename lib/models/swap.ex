defmodule Cashu.Swap do
  alias Cashu.{BlindedMessage, BlindedSignature, Proof}

  @type swap_request :: %{
          inputs: [Proofs.t()],
          outputs: [BlindedMessage.t()]
        }

  @type swap_response :: %{signatures: [BlindedSignature.t()]}

  def swap_request(%{inputs: _, outputs: _} = req) do
    Jason.encode(req)
  end

  def swap_response(%{signatures: _} = resp) do
    Jason.encode(resp)
  end

  def validate(%{signatures: sigs}) do
    BlindedSignature.validate_sig_list(sigs)
  end

  def validate(%{inputs: inputs, outputs: outputs} = swap_req) do
    with %{errors: []} <- Proof.validate_proof_list(inputs),
         %{errors: []} <- BlindedMessage.validate_bm_list(outputs) do
      {:ok, swap_req}
    end
  end
end
