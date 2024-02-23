defmodule BDHKETest do
  use ExUnit.Case

  alias Bitcoinex.Secp256k1.{Math, Point, PrivateKey}
  alias Cashu.BDHKE

  setup do
    secret_message = "supersecretmsg"

    secret_point = %Point{
      x:
        165_428_529_674_300_850_711_470_358_265_510_981_046_187_411_838_897_604_847_603_594_356_633_567_269_946_251_154_765_544_582_914_210_265_139_411_058_617_014_014_955_866_800_369_281_731_932_606_973_475_449_889_077,
      y:
        44_992_216_485_837_052_131_086_138_767_480_732_229_397_183_462_071_939_149_692_371_149_403_731_458_246,
      z: 0
    }

    blinding_factor = %PrivateKey{
      d:
        59_819_602_499_272_341_213_100_391_504_737_638_579_839_792_882_958_090_364_791_788_378_265_695_942_797
    }

    bob_privkey = %PrivateKey{
      d:
        47_437_669_545_325_492_424_569_563_321_792_550_575_318_170_499_197_377_132_293_058_206_264_810_090_011
    }

    bob_pubkey = PrivateKey.to_point(bob_privkey)

    blinded_point = %Point{
      x:
        77_159_601_893_659_699_623_859_993_964_889_035_746_054_909_217_819_999_318_193_247_812_104_419_894_542,
      y:
        34_189_797_318_307_817_155_934_877_944_290_070_857_876_974_320_905_663_111_100_833_630_285_077_249_997,
      z: 0
    }

    commitment_point = %Point{
      x:
        29_906_010_561_444_270_207_077_048_185_412_362_687_772_004_356_240_833_255_426_061_106_935_787_681_379,
      y:
        107_902_611_057_875_541_122_879_735_170_648_486_454_545_598_618_359_320_247_388_931_673_998_630_230_067,
      z: 0
    }

    unblinded_point = %Bitcoinex.Secp256k1.Point{
      x:
        6_926_516_631_442_612_919_967_864_756_916_302_857_632_671_603_926_317_444_090_266_071_882_437_486_257,
      y:
        27_974_101_066_102_506_144_090_919_693_723_041_956_919_162_837_028_908_850_516_403_602_143_893_207_305,
      z: 0
    }

    [
      secret_msg: secret_message,
      secret_point: secret_point,
      blinding_factor: blinding_factor,
      bob_privkey: bob_privkey,
      bob_pubkey: bob_pubkey,
      blinded_point: blinded_point,
      commitment_point: commitment_point,
      unblinded_point: unblinded_point
    ]
  end

  describe "Blind DH Key exchange" do
    test "hash a message to the curve", context do
      {:ok, %Point{} = point} = BDHKE.hash_to_curve(context[:secret_msg])
      assert point == context[:secret_point]
    end

    test "create a blind point from two secrets", context do
      expected_point = context[:blinded_point]
      {:ok, blinded_point, _} = BDHKE.blind_point(context[:secret_msg], context[:blinding_factor])

      assert blinded_point == expected_point
    end

    test "sign a blinded point, return c_", context do
      expected_c_ = context[:commitment_point]
      {:ok, c_, _e, _s} = BDHKE.sign_blinded_point(context[:blinded_point], context[:bob_privkey])
      assert c_ == expected_c_
    end

    test "unblind signature", context do
      expected_c = context[:unblinded_point]

      {:ok, c} =
        BDHKE.generate_proof(
          context[:commitment_point],
          context[:blinding_factor].d,
          context[:bob_pubkey]
        )

      assert expected_c == c
    end

    test "create and verify DLEQ", context do
      {:ok, e, s} = BDHKE.mint_create_dleq(context[:blinded_point], context[:bob_privkey])
      assert is_integer(e)
      assert is_integer(s)

      assert BDHKE.verify_dleq(
               context[:blinded_point],
               context[:commitment_point],
               e,
               s,
               context[:bob_pubkey]
             )
    end
  end

  describe "BDHKE utility functions" do
    test "negate a point" do
      {:ok, %Point{x: xb} = b_point, _} = BDHKE.blind_point("supersecretmsg2")
      {:ok, %Point{x: xn} = negated} = BDHKE.negate(b_point)

      assert xb == xn
      assert %Point{x: 0, y: 0, z: 0} == Math.add(b_point, negated)
    end

    test "hash a set of pubkeys together" do
      func =
        with {:ok, privkey} <- BDHKE.random_number() |> PrivateKey.new(),
             do: PrivateKey.to_point(privkey)

      hash = Stream.repeatedly(fn -> func end) |> Enum.take(4) |> BDHKE.hash_pubkeys()
      assert byte_size(hash) == 32
    end
  end
end
