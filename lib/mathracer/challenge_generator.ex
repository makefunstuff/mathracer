defmodule Mathracer.ChallengeGenerator do
  alias Challenge

  defmodule Challenge do
    defstruct [:operator, :operands, :answer, :error]
  end

  def new do
    operator = [:+, :-, :*, :/] |> Enum.shuffle() |> List.first()
    operands = [get_operand(), get_operand()]

    %Challenge{
      operator: operator,
      operands: operands,
      error: Enum.random(0..2)
    }
    |> calculate_answer()
  end

  def has_correct_answer?(%Challenge{error: 0}),
    do: true

  def has_correct_answer?(%Challenge{error: error}) when is_integer(error),
    do: false

  def calculate_answer(
        %Challenge{
          operator: operator,
          operands: operands,
          error: error
        } = challenge
      ) do
    %{challenge | answer: apply(Kernel, operator, operands) - error}
  end

  defp get_operand do
    Enum.random(1..10)
  end

  defimpl String.Chars, for: Challenge do
    def to_string(%Challenge{
          operator: operator,
          operands: [a, b],
          answer: answer
        }) do
      "#{a} #{operator} #{b} = #{answer}"
    end
  end
end
