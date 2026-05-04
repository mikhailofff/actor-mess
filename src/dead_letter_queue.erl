-module(dead_letter_queue).
-behaviour(gen_server).

-export([start_link/0, push/1, get_all/0, clear/0, requeue_all/0]).
-export([init/1, handle_cast/2, handle_call/3]).

-record(state, {}).

-record(dlq, {
    id,
    task,
    retries
}).

start_link() ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).

push(Item) ->
    gen_server:cast({global, ?MODULE}, {push, Item}).

get_all() ->
    gen_server:call({global, ?MODULE}, get_all).

clear() ->
    mnesia:transaction(fun() ->
        mnesia:clear_table(dlq)
    end).

requeue_all() ->
    {atomic, Items} =
        mnesia:transaction(fun() ->
            mnesia:foldl(fun(Row, Acc) -> [Row | Acc] end, [], dlq)
        end),

    lists:foreach(fun(#dlq{task = Task}) ->
        job_queue:push(Task, 1),
        io:format("Requeue DLQ task ~p~n", [Task])
    end, Items),

    clear().

init([]) ->
    {ok, #state{}}.

handle_cast({push, Item}, State) ->
    Id = erlang:unique_integer([monotonic]),

    Task = maps:get(task, Item),
    Retry = maps:get(retries, Item),

    mnesia:transaction(fun() ->
        mnesia:write(#dlq{
            id = Id,
            task = Task,
            retries = Retry
        })
    end),

    {noreply, State}.

handle_call(get_all, _From, State) ->
    {atomic, Data} =
        mnesia:transaction(fun() ->
            mnesia:foldl(fun(Row, Acc) -> [Row | Acc] end, [], dlq)
        end),

    {reply, Data, State}.
