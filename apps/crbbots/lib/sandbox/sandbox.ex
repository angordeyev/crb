defmodule S do
  require Logger

  def writers do    
    PoloniexBroadcaster.start_link() 
    DbSaverBot.start_link(PoloniexBroadcaster)       
    
    OkexBroadcaster.start_link() 
    DbSaverBot.start_link(OkexBroadcaster)       

    #BinanceBroadcaster.start_link()
    #DbSaverBot.start_link(BinanceBroadcaster)
  end  


  def okex_test do
    okex_broadcaster = OkexBroadcaster.start_link()
    EventsBot.start_link(OkexBroadcaster)
  end  

  def binance_test do
    binance_broadcaster = BinanceBroadcaster.start_link()
    EventsBot.start_link(BinanceBroadcaster)
  end
  

  def cmp do
    a = poloniex_data()
    b = binance_data()
    o = Enum.zip(a,b)
    |> Enum.map(fn({[date, plx], [_, bnc]}) -> [date, Float.parse(plx), Float.parse(bnc)] end) 
    |> Enum.map(fn([date, {plx, ""}, {bnc, ""}]) -> [date, plx, bnc, ((bnc / plx) - 1) * 100 ] end) 
    |> Enum.map(fn([date, plx, bnc, cmp]) -> "#{date};#{plx};#{bnc};#{cmp};" end)
    |> Enum.join("\n")

    File.write! "cmp2.csv", :erlang.term_to_binary(o)
      
  end

  def binance_data do
    # https://www.binance.com/api/v1/klines?symbol=LTCBTC&interval=3m&startTime=1546300800000&endTime=1548979199000
    { :ok, %HTTPoison.Response{body: body} } = HTTPoison.get "https://www.binance.com/api/v1/klines?symbol=LTCBTC&interval=5m&startTime=1546300800000&endTime=1548979199000" 
    items = Poison.decode! body 
    items 
     |> Enum.map(fn([time,_,_,_,close,_,_,_,_,_,_,_,]) -> [DateTime.from_unix(div(time, 1000)), close] end)
     |> Enum.map(fn([{:ok, time}, close]) -> [to_string(time), close] end)
      #|> Enum.map(fn([time,_,_,_,close,_,_,_,_,_,_,_,]) -> [DateTime.from_unix((time/1000)), close] end)
    #o = PoloniexApi.chart_data("2019-01-01T00:00:00Z", "2019-01-31T23:59:59Z") 
      # |> Enum.map(
      #   fn (x) -> "" end 
      # ) 
    #File.write! "binance_january.data", :erlang.term_to_binary(o)
  end

  def okes_pairs do 

  end


  def poloniex_data do
    {:ok, %{"candleStick" => items}} = PoloniexApi.chart_data("2019-01-01T00:00:00Z", "2019-01-31T23:59:59Z") 
    items |> Enum.map(
      fn %{"date" => date, "close" => close} -> [to_string(DateTime.from_unix!(date)), to_string(close)] end
    )
    #File.write! "poloniex_january.data", :erlang.term_to_binary(o)
  end

  def sl() do    
    DateTime.utc_now() |> to_string |> IO.puts
    spawn_link(__MODULE__, :sl_process, [1])
  end

  def sl_process(counter) do
    if rem(counter, 1000000000) == 0 do
      DateTime.utc_now() |> to_string |> IO.puts
      #IO.puts "hi"
    end
    #counter = 

    #Process.sleep(1000)
    #DateTime.utc_now() |> to_string |> IO.puts
    sl_process(counter +  1)
  end


  def arb do
    #Se.start_link "big.stat"; ArbitrageBot.start_link
    #Se.start_link "2018-12-14-11-50-50.stat"; ArbitrageBot.start_link    
    Se.start_link; ArbitrageBot.start_link
  end

  def events do    
    PoloniexBroadcaster.start_link; EventsBot.start_link PoloniexBroadcaster
  end

  def wet_run do
    PoloniexBroadcaster.start_link; ArbitrageBot.start_link
  end
  
  def with_test(v) do
    g = 10
    c = 20

    with a when a == 10 <- g,
         b when b == 1 <- c 
    do

      :okk
    # else
    #   _ -> nil  
    end    
  end

  def account_update_message do
    PoloniexBroadcaster.account_update_message(["n", 7, 3, 1, "1.2", "20", "", "20"])
  end

  def empty(p) do

  end

  def double(d) do
    d * d
  end

  def fortest do
    for i <- 1..10 do
      if i == 3 do
        :a
      end
    end
  end
  

  def new_exception do
    raise "oops"
  end

  def gather do
    
  end

  def l do
    Logger.info("hi")
  end

  def source do
    Se.start_link "big.stat"; EventsBot.start_link Se; 
  end

  def db do
    Se.start_link; EventsBot.start_link Se; 
  end

  def start do
    Se.start_link; EventsBot.start_link; MarginBot.start_link;
  end

  def lmdb do
    {:ok, env} = :elmdb.env_open('./tmp/lmdbe', [{:max_dbs, 1024}]);  
    {:ok, dbi1} = :elmdb.db_open(env, "db1", [:create]); 
    {:ok, dbi2} = :elmdb.db_open(env, "db2", [:create])
  end

  def balance1 do 
    %{
      "BTC" => Decimal.new("1000"),
      "ETC" => Decimal.new("1000"),
      "REP" => Decimal.new("1000"),
      "USDT" => Decimal.new("1000")
    }
  end

  def sell_o do
    [%{amount: "100", pair: "USDT_ETC", rate: "1.43036138"}, %{amount: "100", pair: "USDT_ETC", rate: "1.43036138"}]
  end

  def buy_o do
    [%{amount: "200", pair: "USDT_ETC", rate: "1.43036138"}, %{amount: "200", pair: "USDT_ETC", rate: "1.43036138"}]
  end

  def evs do
    sell_orders = [%{amount: "100", pair: "USDT_ETC", rate: "1.43036138"}, %{amount: "100", pair: "USDT_ETC", rate: "1.43036138"}]
    Enum.map(
      sell_orders, 
      fn x -> 
        [denominator, numerator] = String.split(x.pair, "_"); 
        {:closed, :sell, String.to_atom(numerator), String.to_atom(denominator), Decimal.new(x.rate)} 
      end)
  end

  def orders_to_events(buy_orders, sell_orders) do
    convert = fn (orders, type) -> 
      Enum.map(
      orders, 
      fn x -> 
        [denominator, numerator] = String.split(x.pair, "_"); 
        {:closed_order, type, String.to_atom(numerator), String.to_atom(denominator), Decimal.new(x.rate)} 
      end)
    end
    convert.(buy_orders, :buy) ++ convert.(sell_orders, :sell)
  end
  

  def orders1 do 
    %{
      buy: [%{amount: "10", pair: "USDT_ETC", rate: "1"}], sell: []
    }    
  end

  def orders do
    %{
      buy_orders: [
        %{amount: "2", pair: "USDT_ETC", rate: "2"},
        %{amount: "1", pair: "USDT_ETC", rate: "1"}
        # %{amount: "21", pair: "BTC_REP", rate: "21"},
        # %{amount: "11", pair: "BTC_REP", rate: "11"}
      ],
      sell_orders: [
        # %{amount: "10", pair: "USDT_ETC", rate: "10"},
        # %{amount: "20", pair: "USDT_ETC", rate: "20"},
        %{amount: "1", pair: "BTC_REP", rate: "50"},
        %{amount: "3", pair: "BTC_REP", rate: "5"}
      ]
    }    
  end  

  def processed_buy(orders) do
    orders.buy_orders |> Enum.map(fn x -> 
      [sell_currency, buy_currency] = String.split(x.pair, "_");
      %{
        buy_currency: buy_currency, 
        sell_currency: sell_currency,
        buy_amount: Decimal.new(x.amount),
        sell_amount: Decimal.mult(Decimal.mult(Decimal.new(x.amount), Decimal.new(x.rate)), Se.one_plus_comission) } 
      end) 
      |> Enum.group_by(fn x -> x.buy_currency end)
      |> Map.values     
  end

  def processed_sell(orders) do
    orders.sell_orders |> Enum.map(fn x -> 
      [buy_currency, sell_currency] = String.split(x.pair, "_");
      %{
        buy_currency: buy_currency,
        sell_currency: sell_currency,
        buy_amount: Decimal.mult(Decimal.mult(Decimal.new(x.amount), Decimal.new(x.rate)), Se.one_minus_comission),
        sell_amount: Decimal.new(x.amount) } 
      end) 
      |> Enum.group_by(fn x -> x.buy_currency end)
      |> Map.values     
  end

  def processed_sum(processed_buy, processed_sell) do
    processed = Enum.concat(processed_buy, processed_sell)
    summed_sell = processed 
    |> Enum.map(
      fn list ->
        {
          hd(list).sell_currency,
          List.foldl(list, Decimal.new("0"), fn x, acc -> Decimal.add(x.sell_amount, acc) end ),        
        }
      end)

    summed_buy = processed 
    |> Enum.map(
      fn list ->
        {
          hd(list).buy_currency,
          List.foldl(list, Decimal.new("0"), fn x, acc -> Decimal.add(x.buy_amount, acc) end ),
        #hd(list).buy_currency,
        #List.foldl(list, Decimal.new("0"), fn x, acc -> Decimal.add(x.buy_amount, acc) end ) 
        }
      end)

    %{sell: summed_sell, buy: summed_buy}
    
  end

  def processed_sum() do
    processed_sum(processed_buy(orders()), processed_sell(orders()))
  end

end

defmodule QueueBroadcaster do
  use GenStage

  @doc "Starts the broadcaster."
  def start_link() do
    GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc "Sends an event and returns only after the event is dispatched."
  def sync_notify(event, timeout \\ 5000) do
    GenStage.call(__MODULE__, {:notify, event}, timeout)
  end

  ## Callbacks

  def init(:ok) do
    {:producer, {:queue.new, 0}, dispatcher: GenStage.BroadcastDispatxer}
  end

  def handle_call({:notify, event}, from, {queue, pending_demand}) do
    queue = :queue.in({from, event}, queue)
    dispatch_events(queue, pending_demand, [])
  end

  def handle_demand(incoming_demand, {queue, pending_demand}) do
    dispatch_events(queue, incoming_demand + pending_demand, [])
  end

  defp dispatch_events(queue, 0, events) do
    {:noreply, Enum.reverse(events), {queue, 0}}
  end

  defp dispatch_events(queue, demand, events) do
    case :queue.out(queue) do
      {{:value, {from, event}}, queue} ->
        GenStage.reply(from, :ok)
        dispatch_events(queue, demand - 1, [event | events])
      {:empty, queue} ->
        {:noreply, Enum.reverse(events), {queue, demand}}
    end
  end
end

defmodule Printer do
  use GenStage

  @doc "Starts the consumer."
  def start_link() do
    GenStage.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    # Starts a permanent subscription to the broadcaster
    # which will automatically start requesting items.
    {:consumer, :ok, subscribe_to: [QueueBroadcaster]}
  end

  def handle_events(events, _from, state) do
    for event <- events do
      IO.inspect {self(), event}
    end
    {:noreply, [], state}
  end
end


defmodule Broadcaster do
  use GenStage

  @doc "Starts the broadcaster."
  def start_link() do
    GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  @doc "Sends an event and returns only after the event is dispatched."
  def sync_notify(event, timeout \\ 5000) do
    GenStage.call(__MODULE__, {:notify, event}, timeout)
  end

  def init(:ok) do
    {:producer, :ok, dispatcher: GenStage.BroadcastDispatcher}
  end

  def handle_call({:notify, event}, _from, state) do
    {:reply, :ok, [event], state} # Dispatch immediately
  end

  def handle_demand(_demand, state) do
    {:noreply, [], state} # We don't care about the demand
  end
end

defmodule SimplePrinter do
  use GenStage

  @doc "Starts the consumer."
  def start_link() do
    GenStage.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    # Starts a permanent subscription to the broadcaster
    # which will automatically start requesting items.
    {:consumer, :ok, subscribe_to: [Broadcaster]}
  end

  def handle_events(event, _from, state) do
    IO.inspect {self(), event}    
    {:noreply, [], state}
  end
end



defmodule Circle do
  @moduledoc "Implements basic circle functions"

  @pi 3.14159

  @spec area(number) :: number
  @doc "Computes the area of circle"
  def area(r), do: @pi*r*r
  
  @spec circumference(number) :: number
  @doc "Computer circumference of a circle"
  def circumference(r), do: 2*r*@pi
end


# defmodule ServerProcess do
  
#   # Server
#   def start(callback_module) do
#     spawn(fn -> 
#       initial_state = callback_module.init
#       loop(callback_module, initial_state)
#     end)
#   end

#   defp loop(callback_module, current_state) do
#     receive do
#       {request, caller} ->
#         {response, new_state} = callback_module.handle_call(request, current_state)
#       send(caller, {:response, response})
#       loop(callback_module, new_state)
#     end
#   end
  
#   # Client
#   def call(server_pid, request) do
#     send(server_pid, {request, self})
#     receive do
#       {:response, response} -> 
#         response
#     end
#   end

# end

# defmodule KeyValueStore do
  
#   def init do
#     HashDict.new
#   end

#   def handle_call({:put, key, value}, state) do  
#     {:ok, HashDict.put(state, key, value)}    
#   end
  
#   def handle_call({:get, key}, state) do    
#     {HashDict.get(state, key), state} 
#   end

# end


# defmodule Direct do  
#   def init(back) do
#     back.()
#   end
# end

# defmodulejkl; Back do 
#   def back do
#     IO.puts "BdfACK"
#   end
# end

# defmodule Sand do

#   def shortlife do 
#     spawn_link printLoop/0
#     :timer.sleep(5000)
#     IO.puts "Finished"
#     Process.exit(self(), :shutdown)
#   end

#   def printLoop do 
#     IO.puts "hello"
#     :timer.sleep(3000)
#     printLoop
#   end  

#   #Process.alive?(p)
# end

defmodule Gencounter.Producer do
  use GenStage

  def start_link(init \\ 0) do
    GenStage.start_link(__MODULE__, init)
  end

  def init(counter) do
    {:producer, counter}
  end

  def handle_demand(demand, state) do
    events = Enum.to_list(state..state + demand - 1)
    {:noreply, events, (state+demand)}
  end  
end

defmodule Gencounter.ProducerConsumer do 
  use GenStage

  require Integer

  def start_link do
    GenStage.start_link(__MODULE__, :state)
  end

  def init(state) do
    {:producer_consumer, state, subscribe_to: [Getcounter.Producer]}
  end

  def handle_events(events, _from, state) do
    numbers = events |> Enum.filter(&Integer.is_even/1)
    {:noreply, numbers, state }
  end

end 

# defmodule Gencounter.Consumer do
#   use GenStage

#   def start_link do
#     GenStage.start_link()
#   end

#   def init(state) do
#     {:consumer, state, subscribe_to: {Getcounter.ProducerConsumer}}
#   end

#   def hanlde_events(events, _from, state) do
#     for event <- events do
#       IO.inspect {self(), event, state}      
#     end
    
#     {:noreply, [], state}
#   end
   
# end

defmodule SimpleBroadcaster do
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
    hostname = '127.0.0.1'   
    port = 80   
    {:ok, connPid} = :gun.open(hostname, port, 
      %{
        :protocols => [:http],
        :retry_timeout => 5000,
        :retry => 72 # try one hour
      }
    )
    {ok, _} = :gun.await_up(connPid)        
    :gun.ws_upgrade(connPid, '/')
    receive do
      {:gun_upgrade, _, streamRef, _, _} -> :upgraded
    end    
    connPid    
    {:producer, connPid, dispatcher: GenStage.BroadcastDispatcher}
  end

  @impl true
  def handle_call({:notify, event}, _from, state) do
    {:reply, :ok, [event], state} # Dispatch immediately
  end

  @impl true
  def handle_info(message, state) do        
    #IO.inspect message        
  end
end






