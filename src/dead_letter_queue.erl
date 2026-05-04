-module(dead_letter_queue).
-behaviour(gen_server).

-export([start_link/0, push/1, get_all/0, clear/0, requeue_all/0]).
-export([init/1, handle_cast/2, handle_call/3]).

-define(TABLE, dlq).

-record(state, {}).

start_link() ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).

push(Msg) ->
    gen_server:cast({global, ?MODULE}, {push, Msg}).

get_all() ->
    gen_server:call({global, ?MODULE}, get_all).

clear() ->
    ets:delete_all_objects(?TABLE).

requeue_all() ->
    lists:foreach(fun({_, Item}) ->
        Task = maps:get(task, Item),
        job_queue:push(Task, 1),
        io:format("Requeue DLQ task ~p~n", [Task])
    end, ets:tab2list(?TABLE)),
    clear().

init([]) ->
    ets:new(?TABLE, [named_table, public, ordered_set]),
    {ok, #state{}}.

handle_cast({push, Item}, State) ->
    Id = erlang:unique_integer([monotonic]),
    ets:insert(?TABLE, {Id, Item}),
    {noreply, State}.

handle_call(get_all, _From, State) ->
    Data = ets:tab2list(?TABLE),
    {reply, Data, State}.
