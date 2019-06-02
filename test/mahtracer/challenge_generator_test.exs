defmodule MathRacer.ChallengeGeneratorTest do
  use ExUnit.Case

  alias Mathracer.ChallengeGenerator
  alias Mathracer.ChallengeGenerator.Challenge

  test "operrands should be in range of 1..10 and error 0..2" do
    %Challenge{operands: [a, b], error: error} = ChallengeGenerator.new()

    assert true = a in 1..10
    assert true = b in 1..10
    assert true = error in 0..2
  end

  test "operator should be one of (+, -, *, /)" do
    %Challenge{operator: operator} = ChallengeGenerator.new()

    assert true = operator in [:+, :-, :*, :/]
  end

  test "challenge should be convertible to string" do
    result =
      %Challenge{operator: operator, operands: [a, b], answer: answer} = ChallengeGenerator.new()

    assert "#{a} #{operator} #{b} = #{answer}" == result |> to_string
  end

  test "new challenge should have non null answer" do
    %Challenge{answer: answer} = ChallengeGenerator.new()

    assert is_integer(answer)
  end

  test "challenge should be falsy or truthy" do
    challenge_one = %Challenge{error: 1}
    challenge_two = %Challenge{error: 0}

    assert false == challenge_one |> ChallengeGenerator.has_correct_answer?()
    assert true == challenge_two |> ChallengeGenerator.has_correct_answer?()
  end
end
