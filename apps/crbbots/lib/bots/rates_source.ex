defmodule RatesSource do

  def rates, do: GenStage.call(RatesSource, :rates, 5000)

end

defmodule StatisticRatesSource do
  use GenStage
  
  defmodule Conf do
    def sleep, do: 1 
  end

  def start_link(file \\ :ok) do
    GenStage.start_link(__MODULE__, file, name: RatesSource)
  end

  @impl true
  def init(:ok) do    
    parent_pid = self()
    #{:ok, env} = :elmdb.env_open('./db/lmdb', [{:max_dbs, 1024}]); 
    {:ok, env} = :elmdb.env_open('./tmp/last/lmdb', [{:max_dbs, 1024}]); 
    
    {:ok, db} = :elmdb.db_open(env, "Poloniex", [:create])
    spawn_link(StatisticRatesSource, :read_cycle, [db, 1, parent_pid])    
    {:producer, %{rates: nil}, dispatcher: GenStage.BroadcastDispatcher, buffer_size: 100000000}    
  end

  @impl true
  def init(file) do    
    parent_pid = self()
    map = fn x -> 
      {numerator, denominator, last_trade_price, lowest_ask, highest_bid, time} 
        = Base.decode64!(String.trim_trailing(x, "\n")) |> :erlang.binary_to_term
      #Process.sleep(1)
      send parent_pid, {denominator, numerator, last_trade_price, lowest_ask, highest_bid, time}      
    end
    #events_loop = fn -> File.stream!(file) |> Stream.map(map) |> Stream.run; IO.puts end
    events_loop = fn -> 
      {:ok, device} = File.read!(file) |> StringIO.open
      stream = device |> IO.binstream(:line)
      stream |> Stream.map(map) |> Stream.run      
    end    
    spawn_link(events_loop)
    {:producer, %{rates: nil}, dispatcher: GenStage.BroadcastDispatcher, buffer_size: 100000000}    
  end

  
  @impl true
  def handle_demand(_demand, state) do
    {:noreply, [], state} # We don't care about the demand
  end

  @impl true
  def handle_info({numerator, denominator, last_trade_price, lowest_ask, highest_bid, time}, %{rates: _rates}) do               
    { 
      :noreply, 
      [{:rate_changed, numerator, denominator, last_trade_price, lowest_ask, highest_bid, time }] , 
      %{        
        rates: %{ {:ETC, :USDT} => last_trade_price}
      }
    }    
  end

  @impl true
  def handle_call(:rates, _from, state) do    
    {:reply, nil, [], state} 
  end  

  def read_cycle(db, counter, parent_pid) do
    case :elmdb.get(db, to_string(counter)) do
      {:ok, value} ->        
        {denominator, numerator, last_trade_price, lowest_ask, highest_bid, is_frozen, time} = :erlang.binary_to_term(value)
        send parent_pid, {denominator, numerator, Decimal.new(last_trade_price), Decimal.new(lowest_ask), Decimal.new(highest_bid), DateTime.from_unix!(time, :millisecond)}      
        read_cycle(db, counter + 1, parent_pid)
      _ -> 
    end
    read_cycle(db, counter + 1, parent_pid)    
  end

end


defmodule ChartRatesSource do
  use GenStage
  
  defmodule Conf do
    def sleep, do: 1 
  end

  def start_link(file \\ :ok) do
    GenStage.start_link(__MODULE__, file, name: RatesSource)
  end

  @impl true
  def init(:ok) do    
    chart = File.read!("lib/Poloniex/sedata/USDT_ETC.data") |> :erlang.binary_to_term |> Enum.take(-60000)    
    parent_pid = self()
    events_loop = fn ->      
      for candle <- chart do        
        %{"weightedAverage" => price} = candle        
        send parent_pid, {:ETC, :USDT, Decimal.new(price)}        
        Process.sleep Conf.sleep        
      end
    end
    spawn_link(events_loop)
    {:producer, %{chart: chart, rates: nil}, dispatcher: GenStage.BroadcastDispatcher}    
  end

  @impl true
  def handle_demand(_demand, state) do
    {:noreply, [], state} # We don't care about the demand
  end

  @impl true
  def handle_info({c, q, rate}, %{chart: chart, rates: _rates}) do               
    { 
      :noreply, 
      [{:rate_changed, c, q, rate }] , 
      %{
        chart: chart, 
        rates: %{ {:ETC, :USDT} => rate}
      }
    }    
  end

  @impl true
  def handle_call(:rates, _from, state) do    
    {:reply, nil, [], state} 
  end  

end


