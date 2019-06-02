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

  def handle_call({:add, player}, _from, %GameState{players: players} = state) do
    case length(players) do
      len when len < 10 ->
        {:reply, {:ok, player}, %{state | players: [player | players]}}

      _ ->
        {:reply, {:error, :game_full_error}, state}
    end
  end
end
