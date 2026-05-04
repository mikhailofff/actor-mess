-module(actor_system_sup).
-behaviour(supervisor).

-export([start_link/0]).
-export([init/1]).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

get_role() ->
    case application:get_env(actor_system, node_role) of
        {ok, Role} -> Role;
        _ -> worker
    end.

init([]) ->
    Role = get_role(),

    BaseChildren = [
        {worker_sup,
         {worker_sup, start_link, []},
         permanent, infinity, supervisor, [worker_sup]}
    ],

    CoreChildren =
        case Role of
            core ->
                [
                    {job_queue,
                     {job_queue, start_link, []},
                     permanent, 5000, worker, [job_queue]},

                    {metrics_server,
                     {metrics_server, start_link, []},
                     permanent, 5000, worker, [metrics_server]},

		    {dead_letter_queue,
		     {dead_letter_queue, start_link, []},
                     permanent, 5000, worker, [dead_letter_queue]}
                ];
            worker ->
                []
        end,

    Children = CoreChildren ++ BaseChildren,

    {ok, {{one_for_one, 5, 10}, Children}}.
