defmodule ArbitrageFinder do
  use GenStage

  def comission, do: Decimal.new("0.002")
  def one_plus_comission, do: Decimal.add(Decimal.new("1"), comission())
  def one_minus_comission, do: Decimal.sub(Decimal.new("1"), comission())
  def delay, do: 500

  def start_link() do
    GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    device = :stdio
    {:consumer, %{device: device, rates: %{}, db: %{trade_amount: 2, trade_margin: Decimal.new("0.001") }}, subscribe_to: [PoloniexBroadcaster]}
  end

  @impl true
  def handle_events(events, _from, %{device: device, rates: rates, db: db}) do
    fold = fn ({:rate_changed, numerator, denominator, last_trade_price, lowest_ask, highest_bid, time}, acc) ->
      if (numerator != :BCH && denominator != :BCH) do
        Map.put(acc, {numerator, denominator}, { last_trade_price, lowest_ask, highest_bid, time })
      else
        acc
      end
    end

    new_rates = List.foldl(events, rates, fold)

    find_arbitrage(%{device: device, rates: new_rates, db: db})
    {:noreply, [], %{device: device, rates: new_rates, db: db}}
  end

  def find_arbitrage(%{device: device, rates: rates, db: db}) do

    {{_, _}, { _, _, _, time }} = Enum.max_by(
      rates,
      fn({{_, _}, { _, _, _, t }}) -> DateTime.to_unix(t, :microsecond) end
    )

    final_curr = :USDT
    to_usdt_rates = Enum.filter(
      rates,
      fn({{numerator, denominator}, value}) -> denominator == :USDT end
    )

    for {{first_numerator, first_denominator}, {first_last_trade, first_lowest_ask, first_highest_bid, _first_time} }  <- to_usdt_rates  do

      seconds = Enum.filter(rates, fn {{n, d}, _} -> d == first_numerator  end)

      for second <- seconds do

        if (second != nil) do
          {{second_numerator, second_denominator}, {second_last_trade, second_lowest_ask, second_highest_bid, _second_time}} = second
          third = Enum.find(
            to_usdt_rates,
            fn ({{nu, de}, _}) -> nu == second_numerator and de == final_curr end
          )
          if third != nil do
            {{third_numerator, third_denominator}, {third_last_trade, third_lowest_ask, third_highest_bid, _third_time}} = third

            source_amount = Decimal.new("1000")
            first_amount = Decimal.div(source_amount, first_lowest_ask)
            second_amount = Decimal.div(first_amount, second_lowest_ask)
            destination_amount = Decimal.mult(second_amount, third_highest_bid)

            #if Decimal.cmp(destination_amount, source_amount) == :gt do

              profit = Decimal.sub(Decimal.mult(Decimal.div(destination_amount, source_amount), Decimal.new("100")), 100)
              #case {second_numerator, second_denominator} do
              #  {:SNT, :BTC } ->
                  if Decimal.cmp(profit, Decimal.new("0.77")) == :gt do

                    # Orders

                    # first
                    first_buy_rate = Decimal.mult(first_lowest_ask,
                      Decimal.add(Decimal.new("1"), db.trade_margin)
                    )
                    first_buy_amount =  Decimal.div(db.trade_amount, first_buy_rate)
                    PoloniexApi.buy(first_numerator, first_denominator, first_buy_rate, first_buy_amount)
                    first_buy_amount_comissioned = Decimal.mult(first_buy_amount, one_minus_comission)

                    Process.sleep(delay)

                    # second
                    second_buy_rate = Decimal.mult(second_lowest_ask,
                      Decimal.add(Decimal.new("1"), db.trade_margin)
                    )
                    second_buy_amount = Decimal.div(first_buy_amount_comissioned, second_buy_rate)
                    PoloniexApi.buy(second_numerator, second_denominator, second_buy_rate, second_buy_amount)
                    second_buy_amount_comissioned = Decimal.mult(second_buy_amount, one_minus_comission)

                    Process.sleep(delay)

                    # third
                    third_sell_rate = Decimal.mult(third_highest_bid,
                      Decimal.sub(Decimal.new("1"), db.trade_margin)
                    )
                    third_sell_amount = second_buy_amount_comissioned
                    PoloniexApi.buy(third_numerator, third_denominator, third_sell_rate, third_sell_amount)

                    # End of orders

                    IO.inspect device, {first_numerator, first_denominator, first_lowest_ask}, []
                    IO.inspect device, {second_numerator, second_denominator, second_lowest_ask}, []
                    IO.inspect device, {third_numerator, third_denominator, third_highest_bid}, []
                    IO.puts device, profit
                    IO.inspect device, time, []
                    IO.puts device, "-------------"
               #   else
               #     nil
                 end


              #  other ->
              # end

              # if Decimal.cmp(profit, Decimal.new("1.5")) == :gt do
              #   IO.inspect {first_numerator, first_denominator, first_lowest_ask}
              #   IO.inspect {second_numerator, second_denominator, second_lowest_ask}
              #   IO.inspect {third_numerator, third_denominator, third_highest_bid}
              #   IO.puts profit
              #   IO.inspect time
              # end
            #end



          end
        end

      end

    end
  end

end

