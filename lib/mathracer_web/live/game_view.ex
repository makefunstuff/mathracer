defmodule MathracerWeb.GameView do
  use Phoenix.LiveView
  alias Mathracer.GameServer
  alias Mathracer.GameServer.{GameState, Player}

  @topic "game_lobby"

  def render(assigns) do
    MathracerWeb.Endpoint.subscribe(@topic)

    MathracerWeb.PageView.render("index.html", assigns)
  end

  def mount(_session, socket) do
    player = Player.new()

    %GameState{players: players, challenge: challenge} = :sys.get_state(GameServer)

    initial_state = %{
      game_state: :INTRO,
      challenge: to_string(challenge),
      players: players,
      player: player,
      countdown: 5
    }

    {:ok, assign(socket, initial_state)}
  end

  # UI events
  def handle_event("join_game", _value, socket) do
    case GameServer.add_player(socket.assigns.player) do
      {:ok, player} ->
        %GameState{players: players} = state = :sys.get_state(GameServer)
        MathracerWeb.Endpoint.broadcast!(@topic, "refresh", state)
        {:noreply, assign(socket, game_state: :STARTED, player: player, players: players)}

      {:error, _error} ->
        {:noreply, assign(socket, game_state: :INTRO) |> put_flash(:error, "No free spots")}
    end
  end

  def handle_event("player_joined", _value, socket) do
    %GameState{players: players} = :sys.get_state(GameServer)
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
    Process.send_after(self(), {:tick, socket.assigns.countdown}, :timer.seconds(1))
    {:noreply, assign(socket, challenge: new_challenge, players: players, game_state: :NEW_ROUND)}
  end

  def handle_info(
        %{
          event: "timer",
          topic: @topic,
          payload: %{new_counter: 0}
        },
        socket
      ) do
    %GameState{players: players} = :sys.get_state(GameServer)
    {:noreply, assign(socket, countdown: 5, game_state: :STARTED, players: players)}
  end

  def handle_info(
        %{
          event: "timer",
          topic: @topic,
          payload: %{new_counter: new_counter}
        },
        socket
      ) do
    Process.send_after(self(), {:tick, new_counter}, :timer.seconds(1))
    {:noreply, assign(socket, countdown: new_counter)}
  end

  def handle_info({:tick, countdown}, socket) do
    new_counter = countdown - 1

    MathracerWeb.Endpoint.broadcast!(@topic, "timer", %{new_counter: new_counter})

    {:noreply, socket}
  end

  def terminate(_reason, socket) do
    _ = GameServer.remove_player(socket.assigns.player)

    %GameState{} = state = :sys.get_state(GameServer)
    MathracerWeb.Endpoint.broadcast!(@topic, "refresh", state)

    {:noreply, socket}
  end

  defp challenge(socket, result) do
    {challenge, player} =
      case GameServer.check_challenge(socket.assigns.player, result) do
        {:ok, {:hit, player}} ->
          {:ok, challenge} = GameServer.new_challenge()

          %GameState{players: players} = :sys.get_state(GameServer)

          MathracerWeb.Endpoint.broadcast!(@topic, "round_end", %{
            new_challenge: to_string(challenge),
            players: players
          })

          {to_string(challenge), player}

        {:ok, {_result, player}} ->
          %GameState{} = state = :sys.get_state(GameServer)
          MathracerWeb.Endpoint.broadcast!(@topic, "refresh", state)

          {socket.assigns.challenge, player}
      end

    %GameState{players: players} = :sys.get_state(GameServer)

    {:noreply,
     assign(socket, player: player, players: players, game_state: :STARTED, challenge: challenge)}
  end
end
