-module(taxa).

-export([main/1]).

main(Args) ->
    Context = args:parse(Args),
    io:format("Context: ~p~n", [Context]),
    erlang:halt(0).
