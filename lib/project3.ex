defmodule Project3 do
    def main(args) do
        #Read command line arguements
        {_,argList,_} = OptionParser.parse(args)
        [numNodes | [numRequests | _]] = argList
        Server.initialize(String.to_integer(numNodes), String.to_integer(numRequests), 0, 0)

        receive do
              {:done, hops} ->
               hops = 1 + hops/(String.to_integer(numNodes)*String.to_integer(numRequests))
               IO.inspect hops
        end

    end
end
