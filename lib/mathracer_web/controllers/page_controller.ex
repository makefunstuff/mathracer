defmodule MathracerWeb.PageController do
  use MathracerWeb, :controller

  alias Phoenix.LiveView

  def index(conn, _params) do
    LiveView.Controller.live_render(conn, MathracerWeb.GameView, session: %{})
  end
end
