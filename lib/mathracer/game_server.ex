defmodule MathRacer.GameServer do
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
    defstruct [:players, :challenge, :is_challenge_solved]

    def new() do
      %__MODULE__{
        players: [],
        challenge: ChallengeGenerator.new(),
        is_challenge_solved: false
      }
    end
  end

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    {:ok, GameState.new()}
  end

  def add_player(player) do
    GenServer.call(__MODULE__, {:add, player})
  end

  def remove_player(player) do
    GenServer.call(__MODULE__, {:remove, player})
  end

  def handle_call({:remove, %Player{id: player_id}}, _from, %GameState{players: players} = state) do
    players
    |> Enum.find(fn %Player{id: id} ->
      player_id == id
    end)
    |> case do
      nil ->
        {:reply, {:ok, %{players: players}}, state}

      player ->
        new_players_list = List.delete(players, player)
        {:ok, {:ok, %{players: new_players_list}, %{state | players: new_players_list}}}
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
end
