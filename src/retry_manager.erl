-module(retry_manager).
-export([retry/3]).

-define(MAX_RETRY, 3).

retry(Id, Task, Retry) ->
    case Retry < ?MAX_RETRY of
        true ->
            timer:sleep(500),
            job_queue:push({Task, Retry + 1});
        false ->
            dead_letter_queue:push({Id, Task})
    end.
