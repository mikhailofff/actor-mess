-module(mnesia_boot).
-export([init/0]).

init() ->
    case mnesia:system_info(running_db_nodes) of
        [] ->
            mnesia:create_schema([node()]),
            mnesia:start(),
            create_tables();
        _ ->
            mnesia:start()
    end.

create_tables() ->
    mnesia:create_table(job, [
        {attributes, [id, task, retries]},
        {disc_copies, [node()]}
    ]),

    mnesia:create_table(dlq, [
        {attributes, [id, task, retries]},
        {disc_copies, [node()]}
    ]).
