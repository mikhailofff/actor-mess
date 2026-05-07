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
    gen_server:call({global, ?MODULE}, clear).

requeue_all() ->
    gen_server:call({global, ?MODULE}, requeue_all).

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

handle_call(clear, _From, State) ->
    Result = mnesia:clear_table(dlq),
    {reply, Result, State};

handle_call(requeue_all, _From, State) ->
    Keys = mnesia:dirty_all_keys(dlq),
    Items = lists:map(fun(Key) -> 
        [Record] = mnesia:dirty_read({dlq, Key}),
        Record
    end, Keys),

    mnesia:clear_table(dlq),

    lists:foreach(fun(#dlq{task = Task}) ->
        job_queue:push(Task, 1)
    end, Items),
    
    {reply, ok, State};

handle_call(get_all, _From, State) ->
    Data = mnesia:dirty_match_object(#dlq{_ = '_'}),
    {reply, Data, State}.

