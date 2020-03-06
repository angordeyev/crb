defmodule ReaderBot do
  use GenStage

  # def start_link(file_name \\ "saved.data") do
  #   if (file_name == saved.data) do
  #     d = DateTime.utc_now
  #     new_file_name = "#{d.year}-#{d.month}-#{d.day}-#{d.hour}-#{d.minute}-#{d.second}"      
  #     GenStage.start_link(__MODULE__, {subscribe_to, new_file_name})
  #   else
  #     GenStage.start_link(__MODULE__, {subscribe_to, file_name})
  #   end
  # end

  # def lines_to_events() do 
  #   File.stream!(path)
  #     |> Stream.map(fn x -> Base.decode64!(String.trim_trailing(x, "\n")) |> :erlang.binary_to_term |> IO.inspect end)
  #     |> Stream.run
  # end


  def read(path) do
    File.stream!(path)
      |> Stream.map(fn x -> Base.decode64!(String.trim_trailing(x, "\n")) |> :erlang.binary_to_term |> IO.inspect end)
      |> Stream.run
  end

  def convert_to_csv(source_path, destination_path) do 
    {:ok, file} = File.open(destination_path, [:append])

    write_to_file = fn(path, term) -> 
      {numerator, denominator, last_trade_price, lowest_ask, highest_bid, time} = term
      s = ";"
      
      line = to_string(numerator) <> s <> to_string(denominator) <> s <> to_string(last_trade_price) <> s <> to_string(lowest_ask) <> s <> to_string(highest_bid) <> s <> to_string(time) <> "\n"
      IO.write(file, line) 

      
    end

    File.stream!(source_path)
      |> Stream.map(
        fn x -> 
          term = Base.decode64!(String.trim_trailing(x, "\n")) |> :erlang.binary_to_term 
          write_to_file.(destination_path, term)
      end)
      |> Stream.run

      IO.puts "finished"     
  end



end