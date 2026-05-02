-module(actor_system_sup).
-behaviour(supervisor).

-export([start_link/0]).
-export([init/1]).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
    Children =
        case node() of
            'node1@mikhailoff' ->
                [
                    {job_queue,
                     {job_queue, start_link, []},
                     permanent, 5000, worker, [job_queue]},

                    {metrics_server,
                     {metrics_server, start_link, []},
                     permanent, 5000, worker, [metrics_server]}
                ];
            _ ->
                []
        end ++
        [
            {worker_sup,
             {worker_sup, start_link, []},
             permanent, infinity, supervisor, [worker_sup]}
        ],

    {ok, {{one_for_one, 5, 10}, Children}}.
