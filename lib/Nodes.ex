defmodule Nodes do
    use GenServer

    def init({:ok, requestNo, curHashVal, masterPID, numRequests, prevHashVal}) do
       Nodes.initial(curHashVal, masterPID, numRequests, prevHashVal)
       {:ok, [requestNo, numRequests, curHashVal,masterPID, %{}]}
    end

    def initial(curHashVal, masterPID, numRequests, prevHashVal) do
      if prevHashVal != 0 do
          GenServer.cast(:"actor#{prevHashVal}", {:join, prevHashVal, curHashVal})
      end
    end

    def handle_call({:printTable}, from, list) do
      t = Enum.at(list, 2)
      IO.inspect t
      l = List.last(list)
      IO.inspect l
      {:reply, nil, list}
    end

    def handle_cast({:join, prevHashVal, curHashVal}, list) do
      # IO.inspect list
      routeTable = List.last(list)
      # IO.inspect routeTable
      mismatchPos = Utilities.matchStrings("#{prevHashVal}", "#{curHashVal}" , 0)
      mismatchChar = String.at(curHashVal,mismatchPos)
      # IO.inspect routeTable
      # IO.inspect routeTable
      # IO.inspect mismatchPos
      if Map.has_key?(routeTable, mismatchPos) do
          # IO.inspect "IN IF HAS KEY"
         if Map.has_key?(routeTable[mismatchPos], mismatchChar) do
            GenServer.cast(:"actor#{routeTable[mismatchPos][mismatchChar]}", {:join, routeTable[mismatchPos][mismatchChar], curHashVal})
         else
            newCell = routeTable[mismatchPos]
            newCell = Map.put(newCell, mismatchChar, curHashVal)
            # IO.inspect newCell
            # IO.inspect "Cell"
            routeTable = Map.put(routeTable, mismatchPos, newCell)
            # IO.inspect routeTable
            # IO.inspect "Cell"
            GenServer.cast(String.to_atom("actor#{curHashVal}"), {:update, routeTable, prevHashVal, curHashVal, mismatchPos})
         end
      else
        newRow = %{}
        newRow = Map.put(newRow, mismatchChar, curHashVal)
        routeTable = Map.put(routeTable, mismatchPos, newRow)
        # IO.inspect routeTable
        GenServer.cast(String.to_atom("actor#{curHashVal}"), {:update, routeTable, prevHashVal, curHashVal, mismatchPos})
      end
      # IO.inspect prevHashVal
      # IO.inspect routeTable

      list = List.replace_at(list, -1, routeTable)
      # IO.inspect list
      {:noreply, list}
    end

    def handle_cast({:update, routeTable, prevHashVal, curHashVal, mismatchPos}, list) do
      # IO.inspect list
      extRouteTable = List.last(list)
      # IO.inspect extRouteTable
      if mismatchPos > 0 do
          extRouteTable = Utilities.copyPrevRouteTable(routeTable, extRouteTable, mismatchPos-1, mismatchPos-1)
          # IO.inspect extRouteTable
      end
      prevMismatchChar = String.at(prevHashVal,mismatchPos)
      curMismatchChar = String.at(curHashVal,mismatchPos)
      lastRow = routeTable[mismatchPos]
      lastRow = Map.delete(lastRow, curMismatchChar)
      # IO.inspect "Printing Last Row after deletion"
      # IO.inspect lastRow
      lastRow = Map.put(lastRow, prevMismatchChar, prevHashVal)
      # IO.inspect "Printing Last Row after insertion"
      # IO.inspect lastRow
      extRouteTable = Map.put(extRouteTable, mismatchPos, lastRow)
      # IO.inspect "Route Table with A and C"
      # IO.inspect extRouteTable
      list = List.replace_at(list, -1, extRouteTable)
      {:noreply, list}
    end

    def handle_cast({:route, srcHashVal, destHashVal, numRequests, numNodes, hops}, list) do
      requestNo = List.first(list)
      if requestNo == numRequests do
        masterPID = Enum.at(list, 3)
        GenServer.cast(masterPID, {:done, hops, numNodes, numRequests})
      else
        if destHashVal == 0 do
          requestNo = requestNo + 1
          destNode = :rand.uniform(numNodes)
          destHashVal = :crypto.hash(:md5, "#{destNode}") |> Base.encode16()
        end
          routeTable = List.last(list)
          mismatchPos = Utilities.matchStrings("#{srcHashVal}", "#{destHashVal}" , 0)
          mismatchChar = String.at(destHashVal,mismatchPos)
        # IO.inspect "#{mismatchPos} #{mismatchChar}"

          if Map.has_key?(routeTable, mismatchPos) do
            if Map.has_key?(routeTable[mismatchPos], mismatchChar) do
                hops = hops + 1
                GenServer.cast(:"actor#{routeTable[mismatchPos][mismatchChar]}", {:route, routeTable[mismatchPos][mismatchChar], destHashVal, numRequests, numNodes, hops})
              else
                # IO.inspect "#{srcHashVal} Reached #{destHashVal}"
                masterPID = Enum.at(list, 3)
                GenServer.cast(masterPID, {:done, hops, numNodes, numRequests})
            end
        end
        GenServer.cast(String.to_atom("actor#{srcHashVal}"), {:route, srcHashVal, 0, numRequests, numNodes, hops})
        list = List.replace_at(list, 0, requestNo)
      end
      {:noreply, list}
    end
end
