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

    Children =
        case Role of
            master ->
                [
                    {master_sup,
                     {master_sup, start_link, []},
                     permanent, infinity, supervisor, [master_sup]}
                ];

            worker ->
                [
                    {worker_sup,
                     {worker_sup, start_link, []},
                     permanent, infinity, supervisor, [worker_sup]}
                ]
        end,

    {ok, {{one_for_one, 5, 10}, Children}}.
