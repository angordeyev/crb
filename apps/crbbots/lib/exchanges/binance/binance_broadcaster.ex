defmodule BinanceBroadcaster do
  use GenStage
  require Logger

  @doc "Starts the broadcaster."
  def start_link() do
    GenStage.start_link(__MODULE__, :ok, name: __MODULE__)    
  end

  @doc "Sends an event and returns only after the event is dispatched."
  def sync_notify(event, timeout \\ 5000) do
    GenStage.call(__MODULE__, {:notify, event}, timeout)
  end

  @impl true
  def init(:ok) do    
    hostname = 'stream.binance.com'   
    port = 9443    
    IO.puts "Connecting binance..."
    {:ok, connPid} = :gun.open(hostname, port, %{:transport => :tls, :protocols => [:http] })    
    # {:ok, connPid} = :gun.open(hostname, port, 
    #   %{
    #     :protocols => [:http]
    #   }
    # )    
    case :gun.await_up(connPid, 5000)  do
      {:ok, :http} -> IO.puts "Successfuly connected to binance."
      other -> 
        IO.inspect other 
        other |> inspect |> Logger.error
    end    
    IO.puts "Upgrading binance protocol..."
    #:gun.ws_upgrade(connPid, '/ws/bnbbtc@depth')
    channels = BinanceApi.Currencies.channels()
    :gun.ws_upgrade(connPid, '/stream?streams=#{channels}')
    
    #:gun.ws_upgrade(connPid, '/')
    IO.puts "Waiting for binance upgrade."
    receive do 
      {:gun_upgrade, _, streamRef, _, _} -> IO.puts "1"
      {:gun_response, ConnPid, _, _, Status, Headers} -> IO.puts "2"              
      {:gun_error, ConnPid, StreamRef, Reason} -> IO.puts "3" 
      other -> IO.inspect other     
    end 
    IO.puts "Connection to binance successfuly completed."
    GenStage.cast(__MODULE__, :connected)    
    {:producer, %{connPid: connPid, last_activity: DateTime.utc_now}, dispatcher: GenStage.BroadcastDispatcher}
  end

  @impl true
  def handle_cast(:connected, state) do    
    #Logger.info "Getting actual rates..."
    #rates = PoloniexApi.rates    
    #Logger.info "Actual rates received."
    {:noreply, [], state}
  end

  @impl true
  def handle_call({:notify, event}, _from, state) do
    {:reply, :ok, [event], state} # Dispatch immediately
  end

  @impl true
  def handle_info({:gun_ws, _connPid, _, {:text, data}}, state) do                    
    with {:ok, %{"data" => %{"asks" => asks, "bids" => bids}, "stream" => stream }} <- Poison.decode data do
      if Enum.count(bids) > 0 and Enum.count(bids) > 0 do
        with [bid, _quantity, _]  <- hd(asks), 
             [ask, _quantity, _]  <- hd(bids) do                    
          stream = hd(String.split(stream, "@"))
          {base_currency, quote_currency} = BinanceApi.Currencies.all_pairs[stream]           
          message = {:rate_changed, :binance, :message, base_currency, quote_currency, 0, bid, ask, false, Ce.now()}          
          {:noreply, [message], state}
        else
          _ -> {:noreply, [], state}
        end      
      else 
        {:noreply, [], state}
      end      
    else
      _ -> {:noreply, [], state}
    end
  end
  
  @impl true
  def handle_info({:gun_up, connPid, :http}, state) do        
    Logger.warn "Connection is up."
    Logger.info "Upgrading connection..."
    :gun.ws_upgrade(connPid, '/')
    receive do
      {:gun_upgrade, _, streamRef, _, _} -> :upgraded
    end
    Logger.info "Connection upgraded."    
    subscribe_to_ticker_data_command(connPid)
    subscribe_to_account_notification_command(connPid)    
    {:noreply, [], state }    
  end

  @impl true
  def handle_info({:gun_down, connPid, :ws, :closed, [], []}, state) do        
    Logger.warn "Connection is down."
    Logger.info "Upgrading connection..."
    :gun.ws_upgrade(connPid, '/')
    receive do
      {:gun_upgrade, _, streamRef, _, _} -> :upgraded
    end
    Logger.info "Connection upgraded."
    subscribe_to_ticker_data_command(connPid)
    subscribe_to_account_notification_command(connPid)    
    {:noreply, [], state }    
  end

  @impl true
  def handle_info({:gun_error, connPid, message}, state) do
    Logger.error "gun error."
    message |> inspect |> Logger.error    
    {:noreply, [], state}    
  end 

  @impl true
  def handle_info(:check_alive, state) do                
    if DateTime.diff(DateTime.utc_now, state.last_activity) > 10 do
      Logger.error "PoloniexBroadcaster is inactive, shutting down."
      TelegramApi.send_message("No rate messages from Poloniex.")
      raise("PoloniexBroadcaster is inactive")
    end
    {:noreply, [], state} 
  end

  @impl true
  def handle_info(message, state) do    
    Logger.error "Unexpected message."
    message |> inspect |> Logger.error    
    {:noreply, [], state}    
  end
  
  def account_update_messages(data) do
    data 
      |> Enum.map(&account_update_message/1) # convert message
      |> Enum.filter(&(&1 != nil)) # filter not parsed messages
  end

  # balance update
  def account_update_message(["b", currency_id, wallet, amount]) do
    with currency when currency != nil <- PoloniexApi.Currencies.number_currencies()[currency_id],
         {amount, ""} <- Float.parse(amount) 
    do                                            
      {:balance_changed, :poloniex, :message, {currency, wallet, amount}}       
    else
      _ -> nil
    end  
  end

  # new order
  def account_update_message(["n", currency_pair_id, order_number, order_type, rate, order_amount, date, starting_amount]) do    
    with {base_currency, quote_currency} <- PoloniexApi.Currencies.pair_by_number(currency_pair_id),
         order_type when order_type in [:sell, :buy] <- PoloniexApi.number_to_order_type(order_type),
         {rate, ""} <- Float.parse(rate),
         {order_amount, ""} <- Float.parse(order_amount),
         {starting_amount, ""} <- Float.parse(starting_amount) 
    do
      {:order_created, :poloniex, :message, {order_number, order_type, base_currency, quote_currency, rate, order_amount, starting_amount, date }}    
    else
      _ -> nil
    end
  end

  # order update
  def account_update_message(["o", order_number, new_amount]) do
    with {new_amount, ""} <- Float.parse(new_amount)
    do
      {:order_updated, :poloniex, :message, {order_number, new_amount}}
    else    
      _ -> nil
    end
  end

  # trade notification
  def account_update_message(["t", trade_id, rate, amount, fee_multiplier, funding_type, order_number]) do
    with {rate, ""} <- Float.parse(rate),
         {amount, ""} <- Float.parse(amount),
         {fee_multiplier, ""} <- Float.parse(fee_multiplier) do
      {:trade_notification, :poloniex, :message, {trade_id, rate, amount, fee_multiplier, funding_type, order_number}}
    else
      _ -> nil
    end      
  end

  # unrecognized
  def account_update_message(_), do: nil

  def handle_demand(_demand, state) do
    {:noreply, [], state} # We don't care about the demand
  end    

  defp subscribe_to_ticker_data_command(connPid) do
    command = %{
      "op" => "subscribe",
      "args" => ["swap/ticker:BTC-USD-SWAP"]
    } |> Poison.encode!
    :gun.ws_send(connPid, {:text, command })        

    
    command = %{
      "op" => "subscribe",
      "args" => ["spot/ticker:ETH-USDT"]
    } |> Poison.encode!
    :gun.ws_send(connPid, {:text, command })        

    command = %{
      "op" => "subscribe",
      "args" => ["spot/ticker:BTC-USDT"]
    } |> Poison.encode!
    :gun.ws_send(connPid, {:text, command })        
  end

  defp subscribe_to_account_notification_command(connPid) do
    Logger.info "Subscribing to account notification data..."
    payload = "nonce=#{PoloniexApi.nonce()}"
    sign = PoloniexApi.sign(payload)
    command = %{
      "command" => "subscribe",
      "channel" => "1000",
      "key": PoloniexApi.key(),
      "payload": payload,
      "sign": sign
    } |> Poison.encode!
    result = :gun.ws_send(connPid, {:text, command })    
    result
  end

  def check(parent_pid) do    
    Process.sleep(10000)
    send parent_pid, :check_alive
    check(parent_pid)
  end

end