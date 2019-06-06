defmodule MathracerWeb.GameView do
  use Phoenix.LiveView
  alias Mathracer.GameServer
  alias Mathracer.GameServer.{GameState, Player}

  require Logger

  @topic "game_lobby"

  def render(assigns) do
    MathracerWeb.PageView.render("index.html", assigns)
  end

  def mount(_session, socket) do
    player = Player.new()

    MathracerWeb.Endpoint.subscribe(@topic)

    {:ok, %GameState{players: players, challenge: challenge, counter: counter}} =
      GameServer.get_game_state()

    initial_state = %{
      game_state: :INTRO,
      challenge: to_string(challenge),
      players: players,
      player: player,
      countdown: counter
    }

    {:ok, assign(socket, initial_state)}
  end

  # UI events
  def handle_event("join_game", _value, socket) do
    case GameServer.add_player(socket.assigns.player) do
      {:ok, player} ->
        {:ok, %GameState{players: players} = state} = GameServer.get_game_state()
        MathracerWeb.Endpoint.broadcast!(@topic, "refresh", state)
        {:noreply, assign(socket, game_state: :STARTED, player: player, players: players)}

      {:error, _error} ->
        {:noreply, assign(socket, game_state: :INTRO) |> put_flash(:error, "No free spots")}
    end
  end

  def handle_event("player_joined", _value, socket) do
    %GameState{players: players} = GameServer.get_game_state()
    {:noreply, assign(socket, players: players)}
  end

  def handle_event("challenge_correct", _value, socket) do
    socket |> challenge(true)
  end

  def handle_event("challenge_wrong", _value, socket) do
    socket |> challenge(false)
  end

  # Pubsub event handlers
  def handle_info(%{event: "refresh", topic: @topic, payload: state}, socket) do
    {:noreply, assign(socket, players: state.players)}
  end

  def handle_info(
        %{
          event: "round_end",
          topic: @topic,
          payload: %{new_challenge: new_challenge, players: players}
        },
        socket
      ) do
    {:ok, :timer_started} = GameServer.restart_game()
    {:noreply, assign(socket, challenge: new_challenge, players: players, game_state: :NEW_ROUND)}
  end

  def handle_info(
        %{
          event: "timer_end",
          topic: @topic,
          payload: %{}
        },
        socket
      ) do
    {:ok, %GameState{players: players, counter: counter}} = GameServer.get_game_state()
    {:noreply, assign(socket, game_state: :STARTED, players: players, countdown: counter)}
  end

  def handle_info(
        %{
          event: "timer",
          topic: @topic,
          payload: %{new_counter: new_counter}
        },
        socket
      ) do
    {:noreply, assign(socket, countdown: new_counter)}
  end

  def terminate(_reason, socket) do
    _ = GameServer.remove_player(socket.assigns.player)

    {:ok, %GameState{} = state} = GameServer.get_game_state()
    MathracerWeb.Endpoint.broadcast!(@topic, "refresh", state)

    {:noreply, socket}
  end

  defp challenge(socket, result) do
    {challenge, player} =
      case GameServer.check_challenge(socket.assigns.player, result) do
        {:ok, {:hit, player}} ->
          {:ok, challenge} = GameServer.new_challenge()

          {:ok, %GameState{players: players}} = GameServer.get_game_state()

          Logger.info("Correct answer restarting round")

          MathracerWeb.Endpoint.broadcast!(@topic, "round_end", %{
            new_challenge: to_string(challenge),
            players: players
          })

          {to_string(challenge), player}

        {:ok, {result, player}} ->
          Logger.info("Wrong answer #{inspect(result)}")
          {:ok, %GameState{} = state} = GameServer.get_game_state()
          _ = MathracerWeb.Endpoint.broadcast!(@topic, "refresh", state)

          {socket.assigns.challenge, player}
      end

    {:ok, %GameState{players: players}} = GameServer.get_game_state()

    {:noreply,
     assign(socket, player: player, players: players, game_state: :STARTED, challenge: challenge)}
  end
end
