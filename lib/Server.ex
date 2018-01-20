defmodule Server do
    use GenServer

    def initialize(numNodes, numRequests, hops, requestNum) do
        # IO.inspect "Master Server Started"
        {:ok, masterPID} = GenServer.start_link(__MODULE__, {:ok, self(), requestNum, numNodes, numRequests, hops}, [])
        Server.setupNodes(numNodes, Nodes, masterPID, numRequests, 0, %{})
    end

    def setupNodes(numNodes, module, masterPID, numRequests, prevHashVal, nodePID) when numNodes <= 1 do
        curHashVal = :crypto.hash(:md5, "#{numNodes}") |> Base.encode16()
        # IO.inspect nodePID
        {:ok, pid} = GenServer.start_link(module, {:ok, 0, curHashVal, masterPID, numRequests, prevHashVal}, name: :"actor#{curHashVal}")
        nodePID = Map.put(nodePID, numNodes, curHashVal)
        :timer.sleep(1000)
        Server.routeMessage(nodePID, numRequests, numNodes)
        # Server.callPrint(nodePID)
    end

    def setupNodes(numNodes, module, masterPID, numRequests, prevHashVal, nodePID) do
        curHashVal = :crypto.hash(:md5, "#{numNodes}") |> Base.encode16()
        {:ok, pid} = GenServer.start_link(module, {:ok, 0, curHashVal, masterPID, numRequests, prevHashVal}, name: :"actor#{curHashVal}")
        prevHashVal = curHashVal
        nodePID = Map.put(nodePID, numNodes, curHashVal)
		    :timer.sleep(1000)
        setupNodes(numNodes - 1,module, masterPID, numRequests, prevHashVal, nodePID)
    end

    def callPrint(nodePID) do
      Enum.each nodePID,  fn {k, v} ->
          GenServer.call(:"actor#{v}", {:printTable})
      end
    end

    def routeMessage(nodePID, numRequests, numNodes) do
      Enum.each nodePID, fn{k, v} ->
        GenServer.cast(:"actor#{v}", {:route, v, 0, numRequests, numNodes, 0})
      end
    end

    def init({:ok, serverPID, requestNum, numNodes, numRequests, hops}) do
        {:ok, [serverPID, requestNum, numNodes, numRequests, hops]}
    end

    def handle_cast({:done, hops, numNodes, numRequests}, list) do
        requestNum = Enum.at(list, 1)
        if requestNum == numNodes * numRequests do
          send List.first(list), {:done, List.last(list)}
          else
        requestNum = requestNum + 1
        serverHops = List.last(list)
        serverHops = serverHops + hops
        # :timer.sleep(10000)
        # IO.inspect serverHops
        # IO.inspect "Server Done"
        list = List.replace_at(list, -1, serverHops)
        list = List.replace_at(list, 1, requestNum)
        end
     {:noreply, list}
    end

end
