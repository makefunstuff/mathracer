defmodule MathRacer.GameServerTest do
  alias MathRacer.GameServer
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
end
