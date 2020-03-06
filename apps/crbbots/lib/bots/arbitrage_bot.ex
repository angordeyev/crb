defmodule ArbitrageBot do
  require Logger
  use GenStage
  
  def comission, do: 0.002       
  def trade_amount, do: 2
  def trade_margin, do: 0.001
  def delay, do: 500

  def start_link() do
    GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end  

  def init(:ok) do            
    Logger.info "Checking Telegram connection..."
    TelegramApi.test_connection    
    
    TelegramApi.send_message "ArbitrageBot started"
    TelegramApi.start_polling
    state = %{
      started: true,      
      profit: 0.7,               
      trade_amount: 1.5, 
      trade_margin: 0.003,
      comission: 0.002,
      order_expire_seconds: 300,

      #-------------------------
      rates: %{},
      arbitrages: %{},
    }        
    update_rates(PoloniexApi.rates, state)
    spawn_link(fn -> expire_check(300) end)
    {:consumer, state, subscribe_to: [PoloniexBroadcaster]}    
  end

  @impl true 
  def handle_events(events, _from, state) do    
    state = events 
      |> Enum.filter(&match?({:rate_changed, :poloniex, :message, _, _, _, _, _, _, _}, &1))
      |> rate_changed(state)    
    {:noreply, [], state}
  end

  def rate_changed(rate_changed_events, state) do
    new_rates = update_rates(rate_changed_events, state.rates)
    state = %{state | rates: new_rates}

    all_pairs = find_all_pairs(state.rates, quoted_currencies(), state.trade_margin)
   
    arbitrages = all_pairs |> Enum.filter(fn {profit, _, _} -> profit >= state.profit end)
    non_arbitrages = all_pairs |> Enum.filter(fn {profit, _, _} -> profit < state.profit end)
    
    # Messages
    added_arbitrages = arbitrages |> Enum.filter(fn {_ , key, _} -> Map.has_key?(state.arbitrages, key) == false end) 
    removed_arbitrages = non_arbitrages |> Enum.filter(fn {_ , key, _} -> Map.has_key?(state.arbitrages, key) end)
    updated_arbitrages = arbitrages |> Enum.filter(fn {_ , key, value} -> Map.has_key?(state.arbitrages, key) and value != state.arbitrages[key] end) 
    spawn_link(__MODULE__, :arbitrage_notify, [added_arbitrages, removed_arbitrages, updated_arbitrages, state.rates, state.started])
    # --------    
     
    fold_remove = fn ({_, key, _}, acc) -> Map.delete(acc, key) end
    new_arbitrages = List.foldl(removed_arbitrages, state.arbitrages, fold_remove)
    state = %{state | arbitrages: new_arbitrages}
    
    fold_add = fn ({profit, key, value}, acc) -> Map.put(acc, key, value) end
    new_arbitrages = List.foldl(arbitrages, state.arbitrages, fold_add)
    state = %{state | arbitrages: new_arbitrages}
  end

  def arbitrage_notify(added_arbitrages, removed_arbitrages, updated_arbitrages, rates, started) do
    # if added_arbitrages != [] do
    #   IO.inspect added_arbitrages
    # end
    to_text = fn {type, b, q, rate, c} ->             
      c_text = if (c != 0 ) do
        :erlang.float_to_binary(c * 100, [ {:decimals, 8}, :compact  ])      
      else
        "0.0"
      end       
      if c_text == "0.0" do
        "#{to_string(type)} #{to_string(b)}/#{to_string(q)} #{Ce.format_num(rate)}" 
      else          
        sign = cond do 
          c > 0.0 -> "+"
          true -> ""
        end
        c_text = :erlang.float_to_binary(c * 100, [ {:decimals, 5}, :compact  ])      
        "#{to_string(type)} #{to_string(b)}/#{to_string(q)} #{Ce.format_num(rate)} #{sign}#{c_text}%" 
      end  

      
    end
    arbitrage_messages = fn (type, arbitrages) ->
      for {profit, _, value} <- arbitrages do        
        "#{type} profit: #{Ce.format_num(profit)}%\n#{to_text.(elem(value, 0))}\n#{to_text.(elem(value, 1))}\n#{to_text.(elem(value, 2))}\n#{Ce.local_now_string()}"         
      end
    end
    added_messages = arbitrage_messages.("added", added_arbitrages)
    remove_messages = arbitrage_messages.("removed", removed_arbitrages)
    updated_messages = arbitrage_messages.("updated", updated_arbitrages)    
    for i <- added_messages do
      TelegramApi.send_message i
      IO.puts i
    end
    for i <- remove_messages do
      TelegramApi.send_message i
      IO.puts i
    end
    for i <- updated_messages do
      TelegramApi.send_message i
      IO.puts i
    end
    if started and added_arbitrages != nil and added_arbitrages != [] do
      spawn_link(__MODULE__, :create_orders, [added_arbitrages, rates])
      #create_orders_async(added_arbitrages, rates)      
    end    
    if started and added_arbitrages != nil and updated_arbitrages != []  do
      spawn_link(__MODULE__, :create_orders, [updated_arbitrages, rates])
      #create_orders_async(added_arbitrages, rates)      
    end
  end

  def create_orders(added_arbitrages, rates) do        
    for {_, _, { {t1, b1, q1, r1, d1}, {t2, b2, q2, r2, d2},  {t3, b3, q3, r3, d3} }} <- added_arbitrages do
      with {trade_price, _, _, _, _, _ } <- rates[{b1, :USDT}] do
        a1 = 1.2 / trade_price
        a2 = a1 * 0.998 / r2
        a3 = a2 * 0.998      
        orders = [
          {t1, b1, q1, r1, a1, d1},
          {t2, b2, q2, r2, a2, d2},
          {t3, b3, q3, r3, a3, d3}
        ] |> Enum.sort(fn({_, _, _, _, _, d1}, {_, _, _, _, _, d2}) -> d1 >= d2 end) 
        
        [{t1, b1, q1, r1, a1, _}, {t2, b2, q2, r2, a2, _}, {t3, b3, q3, r3, a3, _}] = orders

        
        with {:ok, %{order_number: _, resulting_trades: rt}} <-PoloniexApi.order({t1, b1, q1, r1, a1}) do
          if rt != [] do          
            with {:ok, %{order_number: _, resulting_trades: rt}} <-PoloniexApi.order({t2, b2, q2, r2, a2}) do
              if rt != [] do
                PoloniexApi.order({t3, b3, q3, r3, a3})    
              end  
            end
          end  
        end
      end  
      

      # OrderBot.add_orders([
      #   {t1, b1, q1, r1, a1},
      #   {t2, b2, q2, r2, a2},
      #   {t3, b3, q3, r3, a3}      
      # ])
    end    
  end

  def create_orders_async(added_arbitrages, rates) do
    for {_, _, { {t1, b1, q1, r1}, {t2, b2, q2, r2},  {t3, b3, q3, r3} }} <- added_arbitrages do
      {trade_price, bid, ask, is_frozen, time } = rates[{b1, :USDT}]
      a1 = 1.5 / trade_price
      spawn_link(fn -> PoloniexApi.order(t1, b1, q1, r1, a1) end)      
      a2 = a1 * 0.998 / r2
      spawn_link(fn -> PoloniexApi.order(t2, b2, q2, r2, a2) end)
      a3 = a2 * 0.998
      spawn_link(fn -> PoloniexApi.order(t3, b3, q3, r3, a3) end)
    end    
  end

  def update_rates(events, rates) do
    fold = fn ({:rate_changed, _exchange, _source ,base_currency, quote_currency, trade_price, bid, ask, is_frozen, time}, acc) ->
      
      { old_trade_price, old_bid, old_ask, old_is_frozen, old_time, _} = 
        if (Map.has_key?(rates, {base_currency, quote_currency})) do
          rates[{base_currency, quote_currency}] 
        else
          { trade_price, bid, ask, is_frozen, time, nil}
        end                  
      trade_price_change = 0  
      bid_change = 0
      ask_change = 0
      if (old_trade_price != 0 && old_bid != 0 && old_ask != 0) do
        trade_price_change = (trade_price - old_trade_price) / old_trade_price
        bid_change = (bid - old_bid) / old_bid
        ask_change = (ask - old_ask) / old_ask
      end
      Map.put(acc, {base_currency, quote_currency}, { trade_price, bid, ask, is_frozen, time , {trade_price_change, bid_change, ask_change} })
    end
    new_rates = List.foldl(events, rates, fold)  
    new_rates
  end

  @impl true
  def handle_info(event, state) do                
    new_state = 
      case event do
        {:user_message, message} -> handle_user_message(event, state)
        _ -> state 
      end    
    {:noreply, [], new_state}    
  end
   

  def handle_event({:rate_changed, _exchange, _source, base_currency, quoute_currency, price, bid, _, is_frozen, time }) do end

  def handle_user_message({:user_message, message}, state) do    
    new_state = case message do
      "/help" ->
        "profit n - set profit"
        state
      "/start" -> 
        TelegramApi.send_message "ArbitrageBot started"
        %{ state | started: true }        
      "/stop" -> %{ state | started: false }
        TelegramApi.send_message "ArbitrageBot stopped"
        %{ state | started: false }        
      "/state" -> 
        TelegramApi.send_message(to_string( if state.started, do: "started", else: "stopped"))        
        state
      "/profit" ->
        TelegramApi.send_message(state.profit)
        state
      "/profit " <> profit_text ->        
        TelegramApi.send_message("profit set to: " <> profit_text )
        {profit, _} = Float.parse(profit_text)        
        %{ state | profit: profit}
      "/trade_margin" ->
        TelegramApi.send_message(state.trade_margin * 100)
        state
      "/trade_margin " <> trade_margin_text ->
        TelegramApi.send_message("trade_margin set to: " <> trade_margin_text )
        {trade_margin_percent, _} = Float.parse(trade_margin_text)        
        trade_margin = trade_margin_percent / 100
        %{ state | trade_margin: trade_margin}
      _ -> state
    end
    new_state
  end

  def find_all_pairs(rates, earn_currencies, trade_margin) do
    result = 
    for earn_currency <- earn_currencies do
      find_all_pairs_for_currency(rates, earn_currency, trade_margin)
    end
    result |> List.foldl([], &(&1 ++ &2)) # Merge lists    
  end

  def find_all_pairs_for_currency(rates, earn_currency, trade_margin) do    
    to_earn_rates = rates |> Enum.filter(fn {{_, q}, _} -> q == earn_currency end)
    result = 
    for {{b1, q1}, {trade_price1, bid1, ask1, _is_frozen1, _time1, {pc1, bc1, ac1}} }  <- to_earn_rates  do     
      seconds = Enum.filter(rates, fn {{_, q}, _} -> q == b1 end)
      orders = 
      for second <- seconds do
        if (second != nil) do
          {{b2, q2}, {trade_price2, bid2, ask2, _is_frozen2, _time2, {pc2, bc2, ac2}}} = second    
          third = Enum.find(to_earn_rates, fn {{b, q}, _} -> b == b2 and q == earn_currency end)
          if third != nil do
            {{b3, q3}, {trade_price4, bid3, ask3, _is_frozen3, _time3, {pc3, bc3, ac3}}} = third          
            source_amount = 1.0
            amount1 = source_amount / ask1
            amount2 = amount1 / ask2
            destination_amount = amount2 * bid3            
            profit = ((destination_amount / source_amount) - 1.0) * 100.0
            {
              profit, 
              { 
                {:buy, b1, q1}, 
                {:buy, b2, q2},
                {:sell, b3, q3}                 
              },
              {  
                {:buy, b1, q1, ask1 * (1 + trade_margin), ac1}, 
                {:buy, b2, q2, ask2 * (1 + trade_margin), ac2}, 
                {:sell, b3, q3, bid3 * (1 - trade_margin), bc3}                 
              }
            }
          end        
        end 
      end                  
      orders |> Enum.filter(&(&1 != nil))
    end
    result |> List.foldl([], &(&1 ++ &2))
  end

  def find_all_pairs_sell(rates, trade_margin) do
    earn_currencies = PoloniexApi.Pairs.all_non_convertable_currencies()
    result = 
    for earn_currency <- earn_currencies do
      find_all_pairs_for_currency_sell(rates, earn_currency, trade_margin)
    end
    result |> List.foldl([], &(&1 ++ &2)) # Merge lists    
  end

  def find_all_pairs_for_currency_sell(rates, earn_currency, trade_margin) do    
    from_earn_rates = rates |> Enum.filter(fn {{b, _}, _} -> b == earn_currency end)
    result = 
    for {{b1, q1}, {trade_price1, bid1, ask1, _is_frozen1, _time1} }  <- from_earn_rates  do     
      seconds = rates 
        |> Enum.filter(fn {{b, q}, _} -> b in quoted_currencies() and q == q1 end) 
        
      orders = 
      for second <- seconds do
        if (second != nil) do
          {{b2, q2}, {trade_price2, bid2, ask2, _is_frozen2, _time2}} = second    
          third = Enum.find(from_earn_rates, fn {{b, q}, _} -> b == b1 and q == b2 end)
          if third != nil do
            {{b3, q3}, {trade_price4, bid3, ask3, _is_frozen3, _time3}} = third          
            source_amount = 1.0
            
            amount1 = source_amount * bid1
            amount2 = amount1 / ask2
            destination_amount = amount2 / ask3            
            profit = ((destination_amount / source_amount) - 1.0) * 100.0
            {
              profit, 
              { 
                {:sell, b1, q1}, 
                {:buy, b2, q2}, 
                {:buy, b3, q3}                 
              },
              {  
                {:sell, b1, q1, bid1 * (1 - trade_margin)}, 
                {:buy, b2, q2, ask2 * (1 + trade_margin)}, 
                {:buy, b3, q3, ask3 * (1 + trade_margin)}                 
              }
            }
          end        
        end 
      end                  
      orders |> Enum.filter(&(&1 != nil))
    end    
    result |> List.foldl([], &(&1 ++ &2))
  end

  def quoted_currencies do 
    [:USDT, :USDC, :BTC, :ETH, :XRP]
  end

  def expire_check(seconds) do    
    PoloniexApi.close_old_orders(seconds)
    Process.sleep(60000)
    expire_check(seconds)
  end

  

end

