defmodule FS do
  
  def start do
    FS.Broadcaster.start_link
    FS.Listener.start_link    
  end

  defmodule Broadcaster do
    use GenStage
    require Logger

    def start_link() do      
      GenStage.start_link(__MODULE__, :ok, name: __MODULE__)    
    end

    @impl true
    def init(:ok) do    
      spawn_link(__MODULE__, :send_messages, [self(), 1])
      {:producer, %{}, dispatcher: GenStage.BroadcastDispatcher}
    end

    @impl true
    def handle_info(message, state) do                  
      {:noreply, [message], state}
    end

    @impl true
    def handle_demand(_demand, state) do
      {:noreply, [], state} # We don't care about the demand
    end

    def send_messages(pid, counter) do     
      #send(pid, counter)
      if (rem(counter, 10000000) == 0) do
        IO.puts "1"
        #IO.inspect counter
      end
      #Process.sleep(1)
      send_messages(pid, counter + 1);      
    end

  end

  defmodule Listener do
    use GenStage
    require Logger

    def start_link() do
      GenStage.start_link(__MODULE__, :ok, name: __MODULE__)    
    end

    @impl true
    def init(:ok) do    
      {:consumer, %{}, [{:subscribe_to, [FS.Broadcaster]}]}
    end

    @impl true 
    def handle_events(events, _from, state) do      
      #if length(events) > 1 do
      #  IO.inspect length(events)
      #end
      # for event <- events do        
      #   if (rem(event, 1000) == 0) do
      #     IO.inspect length(events)
      #   end  
      # end      
      {:noreply, [], state}
    end

  end

  def fail do
    IO.puts "in fail"
    Process.sleep(1000)
    raise("errors")
  #   pid = spawn(fn -> Process.sleep(1000); raise("Something went wrong") end)
  #   Process.monitor(pid)

  #   receive do      
  #     {:DOWN, _, :process, _, msg} ->        
  #       IO.inspect msg
  #     :ok
  #   end

  #   # spawn_link(fn ->
  #   #   Process.flag(:trap_exit, true)      
  #   #   pid = spawn(fn -> Process.sleep(2000); raise("Something went wrong") end)
  #   #   Process.monitor(pid)
  #   #   # receive do
  #   #   #    msg -> IO.inspect(msg)
  #   #   # end
  #   # end)
  #   # for i <- 1..1000 do
  #   #   IO.puts i
  #   #   Process.sleep 600
  #   # end
  end

  def fail_in_second do
    {:ok, spawn_link(fn -> IO.puts "started"; Process.sleep(3000);  raise("errors"); end)}    
  end

end

defmodule Stack do
  use GenStage

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  ## Callbacks

  @impl true
  def init(stack) do
    {:ok, stack}
  end

  @impl true
  def handle_call(:pop, _from, [head | tail]) do
    {:reply, head, tail}
  end

  @impl true
  def handle_cast({:push, head}, tail) do
    {:noreply, [head | tail]}
  end
end