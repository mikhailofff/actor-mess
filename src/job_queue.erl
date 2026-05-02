-module(job_queue).
-behaviour(gen_server).

-export([start_link/0, push/1]).
-export([init/1, handle_cast/2, handle_info/2, handle_call/3]).

-define(TABLE, job_queue).

-record(state, {
    workers = []
}).

start_link() ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).

push(Task) ->
    gen_server:cast({global, ?MODULE}, {push, Task}).

init([]) ->
    ets:new(?TABLE, [named_table, public, ordered_set]),
    erlang:send_after(500, self(), tick),
    {ok, #state{}}.

handle_cast({push, Task}, State) ->
    Id = erlang:unique_integer([monotonic]),
    ets:insert(?TABLE, {Id, Task, 0}), %% 0 — retry count
    dispatch(State);

handle_cast({worker_ready, Pid}, State=#state{workers=Ws}) ->
    dispatch(State#state{workers=[Pid | Ws]}).

dispatch(State=#state{workers=[W | Rest]}) ->
    case ets:first(?TABLE) of
        '$end_of_table' ->
            {noreply, State};
        Key ->
            [{Key, Task, Retry}] = ets:lookup(?TABLE, Key),
            ets:delete(?TABLE, Key),
            gen_server:cast(W, {process, Key, Task, Retry}),
            dispatch(State#state{workers=Rest})
    end;
dispatch(State) ->
    {noreply, State}.

handle_call(_Msg, _From, State) ->
    {reply, ok, State}.

handle_info(tick, State) ->
    erlang:send_after(500, self(), tick),
    dispatch(State).
