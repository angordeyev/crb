defmodule OkexApi do

  def get_pairs do
    transform = fn(x) ->
      x["symbol"]
    end
    %{"data" => items} = Ce.http_get "https://www.okex.com/v2/spot/markets/products"# |> Enum.take(3)
    items |> Enum.map(transform)   
  end

  def spot_channels do
    get_pairs() |> Enum.map(fn(x) -> 
      [base_currency, quote_currency] = x |> String.upcase |> String.split("_")      
      "spot/ticker:#{base_currency}-#{quote_currency}"
    end)  
  end  

end  