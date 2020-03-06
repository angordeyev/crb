defmodule Db do 
  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)    
  end

  def start_link(db_name) do
    GenServer.start_link(__MODULE__, db_name)    
  end

  @impl true
  def init(db_name) do       
    {:ok, env} = :elmdb.env_open('./db', [{:max_dbs, 100000}])    
    if db_name != nil do
      {:ok, db} = :elmdb.db_open(env, db_name, [:create])    
      if (:elmdb.get(db, "counter") == :not_found) do
        :elmdb.put(db, "counter", "0")  
      end
      {:ok, {env, db}}    
    else
      {:ok, db} = :elmdb.db_open(env, [:create])          
      {:ok, {env, db}}    
    end    
  end

  @impl true
  def handle_call(:list, _from, {env, db}) do
    {:ok, txn} = :elmdb.ro_txn_begin(env)
    {:ok, cur} = :elmdb.ro_txn_cursor_open(txn, db)    
    result = get_list(cur, [])
    :elmdb.ro_txn_cursor_close(cur)
    {:reply, result, {env, db}}
  end

  defp get_list(cur, result) do
    case :elmdb.ro_txn_cursor_get(cur, :next) do
      {:ok, key, _value} -> get_list(cur, [key | result]) |> Enum.reverse
      :not_found -> result |> Enum.reverse
    end  
  end  

  def list(pid) do
    GenServer.call(pid, :list)
  end

  def list() do
    GenServer.call(__MODULE__, :list)
  end

  @impl true
  def handle_cast({:put, item}, {env, db}) do
    {:ok, txn} = :elmdb.txn_begin(env)
    {:ok, counter_text} = :elmdb.txn_get(txn, db, "counter")
    {counter, _} = Integer.parse(counter_text)
    new_counter_text = to_string(counter + 1)
    :ok = :elmdb.txn_put(txn, db, new_counter_text, item)             
    :ok = :elmdb.txn_put(txn, db, "counter", new_counter_text)             
    :elmdb.txn_commit(txn)            
    {:noreply, {env, db}}
  end

  @impl true
  def handle_cast({:put, key, value}, {env, db}) do    
    {:ok, txn} = :elmdb.txn_begin(env)
    :ok = :elmdb.txn_put(txn, db, key, value)             
    :elmdb.txn_commit(txn)            
    {:noreply, {env, db}}
  end

  def put(pid, item) do
    GenServer.cast(pid, {:put, item})
  end  

  def put(pid, key, value) do
    GenServer.cast(pid, {:put, key, value})
  end

end