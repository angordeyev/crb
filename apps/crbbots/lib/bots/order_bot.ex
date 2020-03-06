defmodule OrderBot do
  require Logger  
  use GenStage
  
  # TODO: 
  # 
  #

  def start_link() do
    GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    state = %{
      orders: %{},
      order_numbers: []
    }            
    {:consumer, state, subscribe_to: [PoloniexBroadcaster]}    
  end

  @impl true 
  def handle_events(events, _from, state) do    
    state = events
      |> Enum.filter(&match?({:balance_changed, :poloniex, :message, _}, &1))
      |> balance_changed(state)    
    state = events
      |> Enum.filter(&match?({:order_created, :poloniex, :message, _}, &1))
      |> order_created(state)
    state = events
      |> Enum.filter(&match?({:order_updated, :poloniex, :message, _}, &1))
      |> order_updated(state)    
    state = events
      |> Enum.filter(&match?({:trade_notification, :poloniex, :message, _}, &1))
      |> trade_notification(state)        
    {:noreply, [], state}
  end

  def add_orders(orders) do
     GenStage.cast(__MODULE__, {:add_orders, orders})
  end

  @impl true 
  def handle_cast({:add_orders, orders}, state) do
    case PoloniexApi.order(hd orders) do
      {:ok, %{order_number: order_number, resulting_trades: resulting_trades}} ->
        resulting_trades |> inspect |> Logger.info

        # message = "Order #{order_number} created."
        # Logger.info message
        # TelegramApi.send_message message        
        updated_orders = %{state.orders | order_number: order_number} 
        state = %{state | orders: updated_orders} 
      other -> 
        IO.puts "other"
        IO.inspect other  
    end  

    orders |> inspect |> Logger.info 
    {:noreply, [], state}
  end

  def balance_changed(events, state) do    
    if events != [] do
      IO.inspect events
    end  
    state
  end

  def order_created(events, state) do
    if events != [] do
      IO.inspect events
    end
    state
  end  

  def order_updated(events, state) do
    if events != [] do
      IO.inspect events    
    end  
    state
  end  

  def trade_notification(events, state) do
    if events != [] do
      IO.inspect events    
    end  
    state
  end  
end