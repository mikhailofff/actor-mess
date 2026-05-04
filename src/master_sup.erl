-module(master_sup).
-behaviour(supervisor).

-export([start_link/0]).
-export([init/1]).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
    Children = [
        {job_queue, {job_queue, start_link, []},
         permanent, 5000, worker, [job_queue]},

        {dead_letter_queue, {dead_letter_queue, start_link, []},
         permanent, 5000, worker, [dead_letter_queue]},

        {metrics_server, {metrics_server, start_link, []},
         permanent, 5000, worker, [metrics_server]}
    ],

    {ok, {{one_for_one, 5, 10}, Children}}.
