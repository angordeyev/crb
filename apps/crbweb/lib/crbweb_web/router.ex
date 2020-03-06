defmodule CrbwebWeb.Router do
  use CrbwebWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", CrbwebWeb do
    pipe_through :browser

    get "/", PageController, :index
  end

  #Other scopes may use custom stacks.
  scope "/api/v1", CrbwebWeb do
    pipe_through :api
    get "/data1", RestController, :data      

  end
end
