defmodule EventsBot do
  use GenStage
    def start_link(subscribe_to \\ Se) do
    GenStage.start_link(__MODULE__, subscribe_to)
  end

  @impl true
  def init(subscribe_to) do
    {:consumer, nil, subscribe_to: [subscribe_to]}
  end

  @impl true
  def handle_events(events, _from, _state) do
    for event <- events do
      case event do
        {:rate_changed, numerator, denominator, rate } ->
          IO.inspect event
        {:balance_changed, %{"ETC" => etc, "USDT" => usdt}} ->
          rounded_usdt = EventsBot.string_num(usdt)
          rounded_etc = EventsBot.string_num(etc)
          total = Decimal.add(usdt, Decimal.mult(etc, Se.rates[{:ETC, :USDT}])) |>to_string |> EventsBot.string_num
          [:red, :bright, "Balance changed, USDT: #{rounded_usdt}, ETC: #{rounded_etc}, Total: #{total} USDT"] |> IO.ANSI.format |> IO.puts
        {:order_closed, type, :ETC, :USDT, rate, amount} ->
          IO.puts "Order closed, #{to_string(type)}, ETC/USDT, rate: #{EventsBot.string_num(rate)}, amount: #{EventsBot.string_num(amount)}"
          IO.puts Sete.orders
        {type, "USDT_ETC", rate, amount} ->
          IO.puts "#{String.capitalize(to_string(type))} ETC/USDT, rate: #{EventsBot.num_trim(rate)}, amount: #{EventsBot.num_trim(amount)}"
        other -> IO.inspect other
      end
    end
    {:noreply, [], nil }
  end

  def string_num(num) do
    Decimal.round(num, 8) |> to_string |> String.trim_trailing("0") |> String.trim_trailing(".")
  end

  def num_trim(num) do
    num |> String.trim_trailing("0") |> String.trim_trailing(".")
  end
end