-module(retry_manager).
-export([retry/3]).

-define(MAX_RETRY, 3).

retry(Id, Task, Retry) ->
    io:format("Retry ~p (~p)~n", [Task, Retry]),

    case Retry < ?MAX_RETRY of
        true ->
            timer:sleep(500),
            gen_server:cast({global, job_queue}, {retry, Id, Task, Retry + 1});
        false ->
	    dead_letter_queue:push(#{
		id => Id,
		task => Task,
		retries => Retry
	    })
    end.
