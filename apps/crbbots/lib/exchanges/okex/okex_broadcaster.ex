defmodule OkexBroadcaster do
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
    hostname = 'real.okex.com'   
    port = 10442    
    Logger.info "Connecting OKEX..."
    {:ok, connPid} = :gun.open(hostname, port, %{:transport => :tls })    
    case :gun.await_up(connPid, 5000)  do
      {:ok, :http} -> Logger.info "Successfuly connected to OKEX."
      other -> 
        Logger.error "Cannot connect to OKEX."
        other |> inspect |> Logger.error
    end    
    Logger.info "Upgrading OKEX protocol..."
    :gun.ws_upgrade(connPid, '/ws/v3')
    Logger.info "Waiting for OKEX upgrade."
    receive do
      {:gun_upgrade, _, streamRef, _, _} -> :upgraded
      Logger.info "OKEX protocol upgraded."
    end 
    Logger.info "Connection to OKEX successfuly completed."
    GenStage.cast(__MODULE__, :connected)
    subscribe_to_ticker_data_command(connPid)    
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
  def handle_info({:gun_ws, _connPid, _, {:binary, obj}}, state) do                    
    message = obj |> :zlib.unzip |> Poison.decode
    case message do 
      {:ok , %{"data" => [%{"best_ask" => ask, "best_bid" => bid, "last" => trade_price, "instrument_id" => instrument_id }] }} ->        
        with [base_currency, quote_currency] <- String.split(instrument_id, "-") do
          base_currency = String.to_atom(base_currency)
          quote_currency = String.to_atom(quote_currency)
          now = DateTime.utc_now |> DateTime.to_unix(:millisecond)
          message = {:rate_changed, :okex, :message, base_currency, quote_currency, trade_price, bid, ask, false, now}       
          {:noreply, [message], state}    
        else
          _ -> {:noreply, [], state}    
        end        
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
      Logger.error "OkexBroadcaster is inactive, shutting down."
      TelegramApi.send_message("No rate messages from OkexBroadcaster.")
      raise("OkexBroadcaster is inactive")
    end
    {:noreply, [], state} 
  end

  @impl true
  def handle_info(message, state) do
    Logger.error "Unexpected message."
    message |> inspect |> Logger.error    
    {:noreply, [], state}    
  end

  def handle_demand(_demand, state) do
    {:noreply, [], state} # We don't care about the demand
  end    

  defp subscribe_to_ticker_data_command(connPid) do    
    command = %{
      "op" => "subscribe",
      "args" => OkexApi.spot_channels()
    } |> Poison.encode!
    :gun.ws_send(connPid, {:text, command })       
  end

  
  def check(parent_pid) do    
    Process.sleep(10000)
    send parent_pid, :check_alive
    check(parent_pid)
  end

end