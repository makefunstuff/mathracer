defmodule MathracerWeb.PageController do
  use MathracerWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
