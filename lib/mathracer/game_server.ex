defmodule Mathracer.GameServer do
  @topic "game_lobby"
  @timeout :timer.seconds(1)

  alias Mathracer.ChallengeGenerator

  alias GameState
  alias Player
  use GenServer

  defmodule Player do
    defstruct [:score, :id]

    def new() do
      %__MODULE__{
        score: 0,
        id: UUID.uuid4()
      }
    end
  end

  defmodule GameState do
    defstruct [:players, :challenge, :is_challenge_solved, :timer, :counter]

    def new() do
      %__MODULE__{
        players: [],
        challenge: ChallengeGenerator.new(),
        is_challenge_solved: false,
        timer: nil,
        counter: 5
      }
    end
  end

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    {:ok, GameState.new()}
  end

  # Public API

  def add_player(player) do
    GenServer.call(__MODULE__, {:add, player})
  end

  def remove_player(player) do
    GenServer.call(__MODULE__, {:remove, player})
  end

  def check_challenge(player, is_correct) do
    GenServer.call(__MODULE__, {:check_challenge, player, is_correct})
  end

  def new_challenge() do
    GenServer.call(__MODULE__, :new_challenge)
  end

  def restart_game() do
    GenServer.call(__MODULE__, :restart_game)
  end

  def get_game_state() do
    GenServer.call(__MODULE__, :get_game_state)
  end

  # Genserver Handlers

  def handle_info(:timeout, %{counter: 1} = state) do
    MathracerWeb.Endpoint.broadcast!(@topic, "timer_end", %{})
    {:noreply, %{state | counter: 5}}
  end

  def handle_info(:timeout, %{counter: counter} = state) do
    new_counter = counter - 1

    MathracerWeb.Endpoint.broadcast!(@topic, "timer", %{new_counter: new_counter})

    {:noreply, %{state | counter: new_counter}, @timeout}
  end

  def handle_call(:get_game_state, _from, state) do
    {:reply, {:ok, state}, state}
  end

  def handle_call(:restart_game, _from, state) do
    {:reply, {:ok, :timer_started}, state, @timeout}
  end


  def handle_call(:new_challenge, _from, state) do
    new_challenge = ChallengeGenerator.new()

    {:reply, {:ok, new_challenge},
     %{state | challenge: new_challenge, is_challenge_solved: false}}
  end

  def handle_call(
        {:check_challenge, %Player{id: player_id} = _player, is_correct},
        _from,
        %GameState{
          players: players,
          challenge: challenge,
          is_challenge_solved: solved
        } = state
      ) do
    with player = %Player{} <- find_player(players, player_id),
         {:correct_answer, true, player} <-
           {:correct_answer, is_correct == ChallengeGenerator.has_correct_answer?(challenge),
            player} do
      {result, updated_player} =
        if !solved, do: {:hit, %{player | score: player.score + 1}}, else: {:late, player}

      new_players_list = List.delete(players, player)

      {:reply, {:ok, {result, updated_player}},
       %{state | players: [updated_player | new_players_list], is_challenge_solved: true}}
    else
      nil ->
        {:reply, {:error, :player_not_found}, state}

      {:correct_answer, false, player} ->
        new_players_list = List.delete(players, player)
        updated_player = %{player | score: player.score - 1}

        {:reply, {:ok, {:miss, updated_player}},
         %{state | players: [updated_player | new_players_list]}}
    end
  end

  def handle_call({:remove, %Player{id: player_id}}, _from, %GameState{players: players} = state) do
    players
    |> find_player(player_id)
    |> case do
      nil ->
        {:reply, {:ok, %{players: players}}, state}

      player ->
        new_players_list = List.delete(players, player)
        {:reply, {:ok, %{players: new_players_list}}, %{state | players: new_players_list}}
    end
  end

  def handle_call({:add, player}, _from, %GameState{players: players} = state) do
    case length(players) do
      len when len < 10 ->
        {:reply, {:ok, player}, %{state | players: [player | players]}}

      _ ->
        {:reply, {:error, :game_full_error}, state}
    end
  end

  defp find_player(players, player_id) do
    players
    |> Enum.find(fn %Player{id: id} ->
      player_id == id
    end)
  end
end
