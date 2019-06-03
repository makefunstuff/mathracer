defmodule Mathracer.GameServerTest do
  alias Mathracer.GameServer
  alias Mathracer.ChallengeGenerator
  alias GameServer.Player

  use ExUnit.Case

  setup do
    Application.stop(:mathracer)
    Application.start(:mathracer)
  end

  test "it can add player if game has free spot" do
    player = %Player{id: "batman"}

    assert {:ok, ^player} = GameServer.add_player(player)
  end

  test "it can not add player game has no free spots" do
    1..10
    |> Enum.map(fn _ ->
      Player.new()
    end)
    |> Enum.each(&GameServer.add_player/1)

    player = Player.new()

    assert {:error, :game_full_error} = GameServer.add_player(player)
  end

  test "it can remove player when player left the game" do
    player = Player.new()

    assert {:ok, ^player} = GameServer.add_player(player)
    assert {:ok, %{players: []}} = GameServer.remove_player(player)
  end

  test "it can increment player score when answer is correct" do
    player = Player.new()

    {:ok, ^player} = GameServer.add_player(player)
    {:ok, challenge} = GameServer.new_challenge()

    result = ChallengeGenerator.has_correct_answer?(challenge)

    assert {:ok, %Player{score: 1}} = GameServer.check_challenge(player, result)
  end

  test "it cannot increment player score when player not found" do
    player = Player.new()

    {:ok, ^player} = GameServer.add_player(player)

    assert {:ok, %{players: []}} = GameServer.remove_player(player)
    assert {:error, :player_not_found} = GameServer.check_challenge(player, true)
  end

  test "it will not increment player score when challenge has been solved already" do
    player = Player.new()
    second_player = Player.new()

    {:ok, ^player} = GameServer.add_player(player)
    {:ok, ^second_player} = GameServer.add_player(second_player)
    {:ok, challenge} = GameServer.new_challenge()

    result = ChallengeGenerator.has_correct_answer?(challenge)

    assert {:ok, %Player{score: 1}} = GameServer.check_challenge(player, result)
    assert {:ok, %Player{score: 0}} = GameServer.check_challenge(second_player, result)
  end

  test "it will decrement player score when challenge has been incorrect" do
    player = Player.new()

    {:ok, ^player} = GameServer.add_player(player)
    {:ok, challenge} = GameServer.new_challenge()

    result = ChallengeGenerator.has_correct_answer?(challenge)

    assert {:ok, %Player{score: -1}} = GameServer.check_challenge(player, !result)
  end
end
