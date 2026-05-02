-module(worker_sup).
-behaviour(supervisor).

-export([start_link/0, start_worker/0]).
-export([init/1]).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

start_worker() ->
    supervisor:start_child(?MODULE, []).

init([]) ->
    {ok, {
        {simple_one_for_one, 5, 10},
        [
            {worker,
             {worker, start_link, []},
             permanent,
             5000,
             worker,
             [worker]}
        ]
    }}.
