defmodule Se do
  use GenStage

  def comission, do: Decimal.new("0.003") 
  
  def one_plus_comission, do: Decimal.add(Decimal.new("1"), comission())
  def one_minus_comission, do: Decimal.sub(Decimal.new("1"), comission())

  def start_link() do
    GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def start_link(file) do        
    GenStage.start_link(__MODULE__, file, name: __MODULE__)
  end

  @impl true
  def init(:ok) do
    StatisticRatesSource.start_link()
    balance = %{ 
      "USDT" => Decimal.new(1000), 
      "ETC" => Decimal.new(1000)      
    }
    send_events()
    {:producer_consumer, %{chart_data: nil, buy_orders: [], sell_orders: [], balance: balance, rates: nil}, subscribe_to: [RatesSource], dispatcher: GenStage.BroadcastDispatcher}    
  end

  @impl true
  def init(:chart) do
    ChartRatesSource.start_link()
    balance = %{ 
      "USDT" => Decimal.new(1000), 
      "ETC" => Decimal.new(1000)  
      #"BTC" => Decimal.new(1000),  
      #"REP" => Decimal.new(1000)
    }
    chart = File.read!("lib/Poloniex/sedata/USDT_ETC.data") |> :erlang.binary_to_term |> Enum.take(1000)
    send_events()
    {:producer_consumer, %{chart_data: chart, buy_orders: [], sell_orders: [], balance: balance, rates: nil}, subscribe_to: [RatesSource], dispatcher: GenStage.BroadcastDispatcher}    
  end

  @impl true
  def init(file) do
    extension = Path.extname(file)
    if extension == ".stat" do 
      StatisticRatesSource.start_link(file)
    end
    #RatesSource.start_link()
    balance = %{ 
      "USDT" => Decimal.new(1000), 
      "ETC" => Decimal.new(1000)      
    }
    #chart = File.read!("lib/Poloniex/sedata/USDT_ETC.data") |> :erlang.binary_to_term |> Enum.take(1000)
    #send_events()
    {:producer_consumer, %{chart_data: nil, buy_orders: [], sell_orders: [], balance: balance, rates: nil}, subscribe_to: [RatesSource], dispatcher: GenStage.BroadcastDispatcher}    
  end

  def send_events() do
    GenStage.cast(__MODULE__, :send_events)
  end

  @impl true
  def handle_cast(:send_events, %{chart_data: chart_data, buy_orders: [], sell_orders: [], balance: balance, rates: rates}) do            
    {:noreply, [], %{chart_data: chart_data, buy_orders: [], sell_orders: [], balance: balance, rates: rates}}
  end

  def process_orders(weightedAverage, chart, balance, buy_orders, sell_orders) do    

    remaining_buy_orders =  Enum.filter(buy_orders, fn x -> Decimal.cmp(Decimal.new(x.rate), weightedAverage) == :lt end)
    remaining_sell_orders =  Enum.filter(sell_orders, fn x -> Decimal.cmp(Decimal.new(x.rate), weightedAverage) == :gt end)

    processed_buy_orders =  Enum.filter(buy_orders, fn x -> Decimal.cmp(Decimal.new(x.rate), weightedAverage) == :gt end)
    processed_sell_orders =  Enum.filter(sell_orders, fn x -> Decimal.cmp(Decimal.new(x.rate), weightedAverage) == :lt end)
    
    closed_orders_events = orders_to_events(processed_buy_orders, processed_sell_orders)    
    sum_orders = processed_order_sum(%{buy_orders: processed_buy_orders, sell_orders: processed_sell_orders })
    new_balance = close_orders(balance, sum_orders)    
    
    balance_changed_events =     
      if (new_balance != balance) do
        [{:balance_changed, new_balance}]
      else
        []
      end

    %{
      events: closed_orders_events ++ balance_changed_events,
      orders: %{chart_data: chart, balance: new_balance, buy_orders: remaining_buy_orders, sell_orders: remaining_sell_orders}
    }
  end

  @impl true
  def handle_demand(_demand, state) do
    {:noreply, [], state} # We don't care about the demand
  end

 
  @impl true
  def handle_info({sell, buy, price}, %{chart_data: chart, buy_orders: buy_orders, sell_orders: sell_orders, balance: balance}) do           
    process_result = process_orders(price, chart, balance, buy_orders, sell_orders)       
    {:noreply, [{sell, buy, price}] ++ process_result.events, process_result.orders}
  end

  @impl true
  def handle_events(events, _from, %{chart_data: chart, buy_orders: buy_orders, sell_orders: sell_orders, balance: balance}) do            
    if (length(events) == 1) do
      {:noreply, events, %{chart_data: chart, buy_orders: buy_orders, sell_orders: sell_orders, balance: balance}}
      [event] = events      
      case event do        
        {:rate_changed, :ETC, :USDT, rate} ->                    
          process_result = process_orders(rate, chart, balance, buy_orders, sell_orders)                 
          {:noreply, [event] ++ process_result.events, process_result.orders}
        _ -> {:noreply, [event], %{chart_data: chart, buy_orders: buy_orders, sell_orders: sell_orders, balance: balance}}
      end  
    else
      {:noreply, events, %{chart_data: chart, buy_orders: buy_orders, sell_orders: sell_orders, balance: balance}}
    end 
  end
  
  def rates() do    
    RatesSource.rates
  end  

  def buy(pair, rate, amount) do    
    GenStage.call(__MODULE__, {:buy, pair, rate, amount}, 5000)
  end

  def buy(numerator, denominator, rate, amount) do      
    buy pair_to_string(numerator, denominator), to_string(rate), to_string(amount)
  end   

  def sell(pair, rate, amount) do    
    GenStage.call(__MODULE__, {:sell, pair, rate, amount}, 5000)
  end

  def sell(numerator, denominator, rate, amount) do      
    sell pair_to_string(numerator, denominator), to_string(rate), to_string(amount)
  end

  def pair_to_string(numerator, denominator) do
    to_string(denominator) <> "_" <> to_string(numerator)
  end

  def orders() do    
    GenStage.call(__MODULE__, :orders, 5000)
  end  

  def balance() do    
    GenStage.call(__MODULE__, :balance, 5000)
  end

  @impl true
  def handle_call({:buy, pair, rate, amount}, _from, %{chart_data: chart_data, buy_orders: buy_orders, sell_orders: sell_orders, balance: balance}) do
    %{pair: pair, rate: rate, amount: amount}
    {:reply, :ok, [{:buy, pair, rate, amount}], %{chart_data: chart_data, buy_orders: [ %{pair: pair, rate: rate, amount: amount} |  buy_orders], sell_orders: sell_orders, balance: balance}} # Dispatch immediately
  end

  @impl true
  def handle_call({:sell, pair, rate, amount}, _from, %{chart_data: chart, buy_orders: buy_orders, sell_orders: sell_orders, balance: balance}) do    
    {:reply, :ok, [{:sell, pair, rate, amount}], %{chart_data: chart, buy_orders: buy_orders, sell_orders: [%{pair: pair, rate: rate, amount: amount} | sell_orders], balance: balance}} # Dispatch immediately
  end

  @impl true
  def handle_call(:orders, _from, state) do    
    {:reply, %{buy_orders: state.buy_orders, sell_orders: state.sell_orders}, [], state} 
  end

  @impl true
  def handle_call(:balance, _from, state) do    
    {:reply, state.balance, [], state} 
  end

  def usdt_etc_data do
    File.read!("lib/Poloniex/sedata/USDT_ETC.data") |> :erlang.binary_to_term    
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

  def processed_order_sum(orders) do
    processed = Enum.concat(processed_buy(orders), processed_sell(orders))
    summed_sell = processed 
    |> Enum.map(
      fn list ->
        {
          hd(list).sell_currency,
          List.foldl(list, Decimal.new("0"), fn x, acc -> Decimal.add(x.sell_amount, acc) end )
        }
      end)

    summed_buy = processed 
    |> Enum.map(
      fn list ->
        {
          hd(list).buy_currency,
          List.foldl(list, Decimal.new("0"), fn x, acc -> Decimal.add(x.buy_amount, acc) end )        
        }
      end)

    %{sell: summed_sell, buy: summed_buy}    
  end

  def close_orders do
    close_orders(Se.balance, S.processed_sum)
  end

  def close_orders(balance, orders) do
    fold = fn(x, acc) -> 
      Map.put(
        acc, 
        elem(x, 0), 
        Decimal.add(elem(x,1), balance[elem(x,0)])        
      ) 
    end
    balance = List.foldl(orders.buy, balance, fold)      
    fold = fn(x, acc) -> 
      Map.put(
        acc, 
        elem(x, 0), 
        Decimal.sub(balance[elem(x,0)], elem(x,1))        
      ) 
    end
    List.foldl(orders.sell, balance, fold)
  end

  def orders_to_events(buy_orders, sell_orders) do
    convert = fn (orders, type) -> 
      Enum.map(
      orders, 
      fn x -> 
        [denominator, numerator] = String.split(x.pair, "_"); 
        {:order_closed, type, String.to_atom(numerator), String.to_atom(denominator), Decimal.new(x.rate), Decimal.new(x.amount)} 
      end)
    end
    convert.(buy_orders, :buy) ++ convert.(sell_orders, :sell)
  end
  
end

defmodule Sete do
  def balance do
    %{ 
      "USDT" => usdt, 
      "ETC" => etc  
    } = Se.balance
    total = Decimal.add(usdt, Decimal.mult(etc, Se.rates[{:ETC, :USDT}]))
    "ETC: #{EventsBot.string_num(etc)}, USDT: #{EventsBot.string_num(usdt)}, TOTAL USDT: #{EventsBot.string_num(total)}"
    #Se.balance    
  end

  def orders do    
    transform = fn x, type -> "  #{type} ETC/ESDT, rate: #{Decimal.round(Decimal.new(x.rate), 8)}, amount: #{Decimal.round(Decimal.new(x.amount), 8)}" end
    compare = fn(x,y) -> Decimal.cmp(Decimal.new(x.rate), Decimal.new(y.rate)) == :gt end
    complete = fn(list, type) -> list |> Enum.sort(compare) |> Enum.map(fn x -> transform.(x, type) end) |> Enum.join("\n") end    
    "Orders:\n" <> complete.(Se.orders.sell_orders, "Sell") <> "\n" <> complete.(Se.orders.buy_orders, "Buy")
  end

end