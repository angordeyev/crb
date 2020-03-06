defmodule BotSupervisor do
  use Supervisor

  def start_link() do
    Supervisor.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    children = [
      PoloniexBroadcaster,
      EventsBot
    ]
    Supervisor.init(children, strategy: :one_for_one)
  end
end