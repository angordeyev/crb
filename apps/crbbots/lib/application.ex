defmodule Crb.Application do
  use Application

  def start(_type, _args) do
    if Application.get_env(:crbbots, :start) == true do
    children = [
        %{
          id: PoloniexBroadcaster,
          start: {PoloniexBroadcaster, :start_link, []}
        },
        %{
          id: ArbitrageBot,
          start: {ArbitrageBot, :start_link, []}
        },
        %{
          id: OrderBot,
          start: {OrderBot, :start_link, []}
        },
        %{
          id: EventsBot,
          start: {EventsBot, :start_link, [PoloniexBroadcaster]}
        }
      ]
      opts = [strategy: :one_for_all, name: Crb.Supervisor]
      Supervisor.start_link(children, opts)
    else
      Supervisor.start_link([], [strategy: :one_for_all, name: Crb.Supervisor])
    end
  end

end