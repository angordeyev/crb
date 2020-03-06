defmodule DbSaverBot do 
  use GenStage

  def start_link(subscribe_to) do
    GenStage.start_link(__MODULE__, subscribe_to)    
  end

  @impl true
  def init(subscribe_to) do    
    {:ok, db} = Db.start_link("#{Atom.to_string(subscribe_to)}-#{Ce.now_text()}}")
    Db.put(db, "counter", "0")        
    {:consumer, db, subscribe_to: [subscribe_to]}    
  end

  @impl true
  def handle_events(events, _from, db) do        
    for {:rate_changed, exchange, :message, base_currency, quote_currency, trade, bid, ask, is_frozen, time} <- events do                  
      item = {base_currency, quote_currency, trade, bid, ask, is_frozen, time} |> :erlang.term_to_binary()        
      Db.put(db, item)      
    end
    { :noreply, [], db }    
  end

  def get_json(db_name) do
    read(db_name)
  end


  def read(db_name) do
    {:ok, env} = :elmdb.env_open('./db', [{:max_dbs, 1024}]); 
    {:ok, db} = :elmdb.db_open(env, db_name, [:create])
    # {:ok, txn} = :elmdb.ro_txn_begin(env)
    # {:ok, cur} = :elmdb.ro_txn_cursor_open(txn, db)
    # {:ok,_, _} = :elmdb.ro_txn_cursor_get(cur, :next)
    read_cycle(db, 1, [])    
  end

  def to_file do
    {:ok, env} = :elmdb.env_open('./db/lmdb', [{:max_dbs, 1024}]); 
    {:ok, db} = :elmdb.db_open(env, "Poloniex", [:create])
    # {:ok, txn} = :elmdb.ro_txn_begin(env)
    # {:ok, cur} = :elmdb.ro_txn_cursor_open(txn, db)
    # {:ok,_, _} = :elmdb.ro_txn_cursor_get(cur, :next)
    {:ok, file} = File.open("55.csv", [:append])
    read_to_file_cycle(file, db, 1)
    :ok
  end

  def read_cycle(db, counter, list) do
    case :elmdb.get(db, to_string(counter)) do
      {:ok, value} ->         
        read_cycle(db, counter + 1, [:erlang.binary_to_term(value) | list])
      _ -> Enum.reverse(list)
    end
    # case :elmdb.ro_txn_cursor_get(cur, :next) do
    #   {:ok, k, v} -> 
    #     IO.inspect(:erlang.binary_to_term(v))
    #     #IO.puts "hi"
    #     read_cycle(cur)
    #   _ -> nil
    # end    
  end

  def read_to_file_cycle(file, db, counter) do
    case :elmdb.get(db, to_string(counter)) do
      {:ok, value} ->          
        {numerator, denominator, rate, lowest_ask, highest_bid, is_frozen, time } = :erlang.binary_to_term(value)
        s = ";"
        time = DateTime.from_unix!(time, :millisecond)
        line = to_string(numerator) <> s <> to_string(denominator) <> s <> to_string(rate) <> s <> to_string(lowest_ask) <> s <> to_string(highest_bid) <> s <> to_string(is_frozen) <> s <> to_string(time) <> "\n"
        IO.write(file, line)
        read_to_file_cycle(file, db, counter + 1)
      _ -> 
   end        
  end

end