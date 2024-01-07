defmodule BDHKETest do
use ExUnit.Case

alias Bitcoinex.Secp256k1.{Point, PrivateKey}
alias Cashu.BDHKE

setup_all do
  secret_message = "supersecretmsg"
  blinding_factor = %PrivateKey{d: 59819602499272341213100391504737638579839792882958090364791788378265695942797}
  bob_privkey = %PrivateKey{d: 47437669545325492424569563321792550575318170499197377132293058206264810090011}
  bob_pubkey = PrivateKey.to_point(bob_privkey)
  blinded_point = %Point{
   x: 77159601893659699623859993964889035746054909217819999318193247812104419894542,
   y: 34189797318307817155934877944290070857876974320905663111100833630285077249997,
   z: 0
 },
  commitment_point = %Point{
   x: 29906010561444270207077048185412362687772004356240833255426061106935787681379,
   y: 107902611057875541122879735170648486454545598618359320247388931673998630230067,
   z: 0
 },
  unblinded_point = 

  [secret_msg: secret_message, blinding_factor: blinding_factor, bob_privkey: bob_privkey, bob_pubkey: bob_pubkey]
end

describe "Blind DH Key exchange" do  
  test "hash a message to the curve", context do
    expected_point =   %Point{
   x: 165428529674300850711470358265510981046187411838897604847603594356633567269946251154765544582914210265139411058617014014955866800369281731932606973475449889077,
   y: 44992216485837052131086138767480732229397183462071939149692371149403731458246,
   z: 0
 }
    {:ok, %Point{} = point} = hash_to_curve(context[:secret_msg])
    assert point == expected_point
  end

  test "create a blind point from two secrets", context do
    setup do
      {:ok, blinded_point, _ } = blind_point(context[:secret_msg], context[:blinding_factor])
      [b_point: blinded_point]
    end
    
    assert blinding_factor == blinding_key
    assert blinded_point == expected_point
  end

  test "sign a blinded point, return c_", context do
    expected_c_ = 
    {:ok, c_, e, s} = sign_blinded_point(context[:blinded_point], context[:bob_privkey])
  end

  test "unblind signature" do

  end

  test "validate unblinded signature" do
    
  end

  test "create DLEQ" do

  end

  test "verify a DLEQ proof" do

  end
  end

describe "BDHKE utiliy functions" do
    test "negate a point" do
  
    end
  
    test "hash a set of pubkeys together" do
  
    end
  end
end