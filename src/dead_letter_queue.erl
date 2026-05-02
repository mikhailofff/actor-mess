-module(dead_letter_queue).
-export([push/1]).

push(Task) ->
    io:format("DLQ: ~p~n", [Task]).
