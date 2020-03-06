defmodule CrbwebWeb.PageController do
  use CrbwebWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
