defmodule MarginBot do
  use GenStage  

  def margin, do: Decimal.new("0.1")
  def margin_count, do: 18
  def amount, do: Decimal.new("600")
  def transaction_amount, do: Decimal.div(amount, margin_count)
  def transaction_amount_string, do: transaction_amount |> Decimal.round(8) |> Decimal.to_string

  def start_link() do
    GenStage.start_link(__MODULE__, %{last_rate: nil, buy_orders: [], sell_orders: []})
  end

  def init(state) do        
    {:consumer, state, subscribe_to: [Se]}    
  end

  def handle_events(events, _from, %{last_rate: last_rate, buy_orders: buy_orders, sell_orders: sell_orders}) do    
    rate_change_events = for {:rate_changed, :ETC, :USDT, _} = event <- events, do: event
    last_event  = Enum.at(rate_change_events, -1)
    
    #ballance_change_events = for {:balance_changed, balance} = event <- events, do: IO.inspect balance
    orders_closed_events = for {:order_closed, type, numerator, denominator, rate, amount } = event <- events, do: event
    handle_closed_events(orders_closed_events)

    case last_event do
      {:rate_changed, :ETC, :USDT, rate} ->        
        if (length(buy_orders) == 0) and (length(sell_orders) == 0) do
          create_initial_orders({:USDT, :ETC, rate})
        else
          {:noreply, [], %{last_rate: rate, buy_orders: buy_orders, sell_orders: sell_orders}}
        end
      x -> 
        {:noreply, [], %{last_rate: last_rate, buy_orders: buy_orders, sell_orders: sell_orders}}
    end
  end

  def handle_closed_events(orders_closed_events) do        
    for {:order_closed, :buy, numerator, denominator, rate, amount } <- orders_closed_events do      
      sell_rate = Decimal.add(rate, Decimal.mult(rate, margin)) |> Decimal.round(8)
      Se.sell numerator, denominator, sell_rate, amount  
    end 
    for {:order_closed, :sell, numerator, denominator, rate, amount } <- orders_closed_events do      
      buy_rate = Decimal.sub(rate, Decimal.mult(rate, margin)) |> Decimal.round(8)
      Se.buy numerator, denominator, buy_rate, amount  
    end
  end

  def create_initial_orders({:USDT, :ETC, rate}) do          
    margin_amount = Decimal.mult(rate, margin)
    new_sell_orders = for i <- 1..div(margin_count,2) do                  
      plus = Decimal.mult(Decimal.new(i), margin_amount)
      sell_rate = Decimal.add(rate, plus) |> Decimal.round(8)
      sell_rate
    end
    for sell_rate <- Enum.reverse(new_sell_orders) do
      Se.sell :ETC, :USDT, sell_rate, transaction_amount
    end
    new_buy_orders = for i <- 1..div(margin_count,2) do            
      minus = Decimal.mult(Decimal.new(i), margin_amount)
      buy_rate = Decimal.sub(rate, minus) |> Decimal.round(8)
      Se.buy :ETC, :USDT, buy_rate, transaction_amount      
      buy_rate
    end
    #new_orders = new_buy_orders ++ new_sell_orders
    # new_buy_orders = Enum.map(new_orders, fn({bo, so}) -> bo end)          
    # new_sell_orders = Enum.map(new_orders, fn({bo, so}) -> so end)  
    {:noreply, [], %{last_rate: rate, buy_orders: [1,2,3], sell_orders: [1,2,3]}}    
  end

end

