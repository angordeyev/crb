defmodule SaverBot do
  use GenStage

  def start_link(file_name \\ nil , subscribe_to \\ PoloniexBroadcaster) do
    if (file_name == nil) do
      d = DateTime.utc_now
      new_file_name = "#{d.year}-#{d.month}-#{d.day}-#{d.hour}-#{d.minute}-#{d.second}"      
      GenStage.start_link(__MODULE__, {subscribe_to, new_file_name})
    else
      GenStage.start_link(__MODULE__, {subscribe_to, file_name})
    end
  end

  @impl true
  def init({subscribe_to, file_name}) do        
    {:ok, file} = File.open(file_name, [:append])
    {:consumer, file, subscribe_to: [subscribe_to]}    
  end

  @impl true
  def handle_events(events, _from, file) do    
    for {numerator, denominator, rate, lowest_ask, highest_bid, is_frozen, now } <- events do            
      item = {numerator, denominator, rate, lowest_ask, highest_bid, is_frozen, now} |> :erlang.term_to_binary() |> Base.encode64       
      IO.write(file, item <> "\n")      
    end
    { :noreply, [], file }
  end

end