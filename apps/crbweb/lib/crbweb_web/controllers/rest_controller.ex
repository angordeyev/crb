defmodule CrbwebWeb.RestController do
  use CrbwebWeb, :controller

  def data(conn, _params) do
    object = DbSaverBot.read("Elixir.OkexBroadcaster-2019-02-21 16:34:05.516119Z}")
      |> Enum.filter(fn x -> match?({:BTC, :USDT, _, _, _, _, _}, x ) end)
      |> Enum.map(fn({quote_currency, base_currency, rate, bid, ask, is_frozen, date}) ->
        date_text = DateTime.from_unix!(date, :millisecond) |> DateTime.to_string()
        %{
          "quote_currency" => quote_currency,
          "base_currency" => base_currency,
          "rate" => rate,
          "bid" => bid,
          "ask" => ask,
          "date" => date_text,
          "timestamp" => date
        }
      end)
    json conn, object
  end
end
