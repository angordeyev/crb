defmodule BinanceApi do

  def get_pairs do
    transform = fn(x) ->
      x["symbol"]
    end
    %{"data" => items} = Ce.http_get "https://www.binance.com/exchange/public/product"
    items
    items |> Enum.map(fn(%{"baseAsset" => base_currency, "quoteAsset" => quote_currency}) -> {String.to_atom(base_currency), String.to_atom(quote_currency)} end)    
  end

  def get_streams_pairs do
    map = get_pairs() 
      |> Enum.reduce %{}, 
        fn ({base_currency, quote_currency}, acc) -> 
          Map.put(acc, String.downcase(to_string(base_currency)) <> String.downcase(to_string(quote_currency)) , {base_currency, quote_currency})
    end
  end  
  
  def get_pairs_stream do
    get_pairs 
    |> Enum.map(fn {base_currency, quote_currency} -> String.downcase(base_currency) <> String.downcase(quote_currency)  end)
    |> Enum.join("/")    
  end

  def spot_channels do
    get_pairs() |> Enum.map(fn(x) -> 
      [base_currency, quote_currency] = x |> String.upcase |> String.split("_")      
      "spot/ticker:#{base_currency}-#{quote_currency}"
    end)  
  end  

end  