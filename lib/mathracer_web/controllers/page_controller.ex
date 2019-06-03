defmodule MathracerWeb.PageController do
  use MathracerWeb, :controller

  alias Mathracer.GameServer
  alias GameServer.GameState

  def index(conn, _params) do
    %GameState{players: players, challenge: challenge} = :sys.get_state(GameServer)

    render(conn, "index.html", players: players, challenge: to_string(challenge))
  end
end
