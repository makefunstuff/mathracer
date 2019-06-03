defmodule MathracerWeb.GameChannel do
  use MathracerWeb, :channel

  alias Mathracer.GameServer
  alias GameServer.GameState

  require Logger

  def join("game:round", _payload, socket = %{assigns: %{player: player}}) do
    case GameServer.add_player(player) do
      {:ok, _player} ->
        %GameState{challenge: challenge} = :sys.get_state(GameServer)

        {:ok, %{challenge: to_string(challenge), id: player.id, score: player.score}, socket}

      {:error, :game_full_error} ->
        {:error, "No free spots"}
    end
  end

  # # It is also common to receive messages from the client and
  # # broadcast to everyone in the current topic (game:lobby).
  # def handle_in("shout", payload, socket) do
  #   broadcast(socket, "shout", payload)
  #   {:noreply, socket}
  # end

  def terminate(_reason, socket = %{assigns: %{player: player}}) do
    Logger.info("player #{player.id} left the game")
    _ = GameServer.remove_player(player)
    {:ok, socket}
  end
end
