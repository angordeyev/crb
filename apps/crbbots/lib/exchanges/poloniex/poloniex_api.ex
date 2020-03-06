defmodule PoloniexApi do
  require Logger

  def key do
    "removed"
  end

  def sign(value) do
    secret = "removed"
    :crypto.hmac(:sha512, secret, value) |> Base.encode16(case: :lower)
  end

  def nonce do
    div(DateTime.utc_now |> DateTime.to_unix(:microsecond), 1000)
  end

  def balances do
    balances = post_command "returnBalances"
    :maps.filter fn _, v -> v != "0.00000000" end, balances
  end

  def usdt_balance do
    post_command("returnBalances")["USDT"]
  end

  def cancel_order(order_number) do
    post_command "cancelOrder", %{orderNumber: order_number}
  end

  def opened_orders(currency_pair) do
    post_command "returnOpenOrders", %{currencyPair: currency_pair}
  end

  def opened_orders do
    case opened_orders("all") do
      {:ok, opened_orders} ->
        {:ok, opened_orders |> Enum.filter(fn x -> elem(x, 1) != [] end)}
      {:error, message} ->
        {:error, message}
    end
  end

  def close_old_orders(expired_seconds), do: spawn_link(__MODULE__, :close_old_orders_process, [expired_seconds])
  def close_old_orders_process(expired_seconds) do
    with {:ok, opened_orders} <- opened_orders("all") do
      for  {k, v}  <-  opened_orders do
        for  %{"date" => order_date_text, "orderNumber" => orderNumber }  <-  v  do
          {:ok, order_date, _} = DateTime.from_iso8601(order_date_text <> "Z")
          if DateTime.diff(DateTime.utc_now, order_date) > expired_seconds do
            cancel_order orderNumber
          end
        end
      end
    end
  end

  def order({type, base_currency, quote_currency, rate, amount}) do
    order_time = Ce.local_now_string()
    rate = :erlang.float_to_binary(rate/1, [{:decimals, 8}, :compact])
    amount = :erlang.float_to_binary(amount/1, [{:decimals, 8}, :compact])
    message = "sending order\n#{to_string(type)} #{base_currency}/#{quote_currency}\nrate:#{rate}, amount:#{amount}\n#{order_time}"
    Logger.info message
    TelegramApi.send_message message
    case post_command to_string(type), %{currencyPair: pair_string(base_currency, quote_currency), rate: rate , amount: amount } do
      {:error, %HTTPoison.Error{id: _, reason: :timeout}} ->
        Logger.warn "Timeout for order " <> order_time
        TelegramApi.send_message "Error: timeout for order\n#{order_time}\n#{Ce.local_now_string()}"
      {:error, reason} ->
        reason |> inspect |> Logger.error
        TelegramApi.send_message("Error: #{inspect(reason)}\nfor order #{order_time}\n#{Ce.local_now_string()}")
      {:ok, %{"error" => error}} ->
        Logger.warn error
        TelegramApi.send_message "Error: #{error}\nfor order #{order_time}\n#{Ce.local_now_string()}"
        {:error, error}
      {:ok, %{"orderNumber" => order_number, "resultingTrades" => resulting_trades}} ->
        Logger.info "Order #{order_time} created with number #{order_number}"
        TelegramApi.send_message "Order #{order_time} created with number #{order_number} \n#{Ce.local_now_string()}"
        {:ok, %{order_number: order_number, resulting_trades: resulting_trades}}
      other -> other
    end
  end

  def buy(base_currency, quote_currency, rate, amount) do
    order({:buy, base_currency, quote_currency, rate, amount})
  end

  def sell(base_currency, quote_currency, rate, amount) do
    order({:sell, base_currency, quote_currency, rate, amount})
  end

  def pair_string(numerator, denominator) do
    to_string(denominator) <> "_" <> to_string(numerator)
  end

  def chart_data(pair) do
    start_time = DateTime.from_iso8601("2017-12-01T00:00:00Z") |> elem(1) |> DateTime.to_unix |>  Integer.to_string
    end_time = DateTime.from_iso8601("2017-12-01T23:59:59Z") |> elem(1) |> DateTime.to_unix |>  Integer.to_string
    post_command "returnChartData", %{currencyPair: pair, period: "300" , start: start_time, end: end_time }
  end

  def chart_data(start_time, end_time) do
    #for pair <- PoloniexApi.Currencies.pairs_numbers() |> Map.keys |> Enum.take 3 do
      chart_data("BTC_LTC", start_time, end_time)
    #end
  end

  def chart_data(pair, start_time, end_time) do
    start_time = DateTime.from_iso8601(start_time) |> elem(1) |> DateTime.to_unix |>  Integer.to_string
    end_time = DateTime.from_iso8601(end_time) |> elem(1) |> DateTime.to_unix |>  Integer.to_string
    post_command "returnChartData", %{currencyPair: pair, period: "300" , start: start_time, end: end_time }
  end

  def rates do
    { :ok, %HTTPoison.Response{body: body} } =
      HTTPoison.get "https://poloniex.com/public?command=returnTicker"
    items = Poison.decode! body
    now = DateTime.utc_now |> DateTime.to_unix(:millisecond)
    map = fn {
      k,
      %{
        "last" => trade_price,
        "lowestAsk" => ask,
        "highestBid" => bid,
        "isFrozen" => is_frozen
      }
    } ->
      [quote_currency, base_currency] = String.split(k, "_")
      {trade_price, _} = Float.parse(trade_price)
      {bid, _} = Float.parse(bid)
      {ask, _} = Float.parse(ask)
      {:rate_changed, :poloniex, :request, String.to_atom(base_currency), String.to_atom(quote_currency), trade_price, bid, ask, Ce.to_boolean(is_frozen), now}
    end
    Enum.map(items, map) |> Enum.filter(fn {_, _, _, base_currency, _, _, _, _, _, _ } -> base_currency != :BCH end)
  end

  def number_to_order_type(number) when number == 0, do: :sell
  def number_to_order_type(number) when number == 1, do: :buy
  def number_to_order_type(_), do: nil


  def post_command(command, params_map \\ %{}) do
    params = "command=#{command}&nonce=#{nonce}" <> map_to_html_params(params_map)
    Logger.debug params
    case HTTPoison.post("https://poloniex.com/tradingApi", params, %{"Key" => key, "Sign" => sign(params), "Content-Type" => "application/x-www-form-urlencoded"}) do
      {:ok, %HTTPoison.Response{body: body} } ->
        {:ok, Poison.decode! body}
      {:error, message}  ->
        message |> inspect |> Logger.error
        {:error, message}
    end
  end

  defp map_to_html_params(params_map) do
    cond do
      params_map == %{} -> ""
      true ->
        Enum.map(params_map, fn {k,v} -> Atom.to_string(k) <> "=" <> to_string(v) end)
          |> Enum.join("&")
          |> (&("&" <> &1)).()
    end
  end

end