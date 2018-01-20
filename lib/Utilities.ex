defmodule Utilities do

  def matchStrings(prevHashVal, curHashVal, pos) do
      if(pos < 32  && String.at(prevHashVal, pos) == String.at(curHashVal, pos)) do
        matchStrings(prevHashVal,curHashVal,pos+1)
      else
        pos
    end
  end

  def copyPrevRouteTable(routeTable, extRouteTable, mismatchPos, rowNo) do
    if rowNo < 0 do
      extRouteTable
    else
      if Map.has_key?(routeTable, rowNo) do
        newRow = routeTable[rowNo]
        extRouteTable = Map.put(extRouteTable, rowNo, newRow)
        # IO.inspect extRouteTable
      end
      copyPrevRouteTable(routeTable, extRouteTable, mismatchPos, rowNo-1)
    end
  end



end
