-module(job_queue).
-behaviour(gen_server).

-export([start_link/0, push/1, push/2]).
-export([init/1, handle_cast/2, handle_info/2, handle_call/3]).

-record(state, {
    workers = []
}).

-record(job, {
    id,
    task,
    retries
}).

start_link() ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).

push(Task, Retry) ->
    gen_server:cast({global, ?MODULE}, {push, Task, Retry}).

push(Task) ->
    gen_server:cast({global, ?MODULE}, {push, Task, 0}).

init([]) ->
    erlang:send_after(500, self(), tick),
    {ok, #state{}}.

%% =========================
%% HANDLERS
%% =========================

handle_cast({push, Task, Retry}, State) ->
    Id = erlang:unique_integer([monotonic]),

    mnesia:transaction(fun() ->
        mnesia:write(#job{id = Id, task = Task, retries = Retry})
    end),

    dispatch(State);

handle_cast({worker_ready, Pid}, State=#state{workers=Ws}) ->
    dispatch(State#state{workers=[Pid | Ws]});

handle_cast({retry, Id, Task, Retry}, State) ->
    mnesia:transaction(fun() ->
        mnesia:write(#job{id = Id, task = Task, retries = Retry})
    end),

    dispatch(State).

%% =========================
%% DISPATCH
%% =========================

dispatch(State=#state{workers=[W | Rest]}) ->

    Result =
        mnesia:transaction(fun() ->
            case mnesia:first(job) of
                '$end_of_table' ->
                    empty;
                Key ->
                    case mnesia:read({job, Key}) of
                        [#job{id = Id, task = Task, retries = Retry}] ->
                            mnesia:delete({job, Key}),
                            {ok, Id, Task, Retry};
                        _ ->
                            empty
                    end
            end
        end),

    case Result of
        {atomic, {ok, Id, Task, Retry}} ->
            gen_server:cast(W, {process, Id, Task, Retry}),
            dispatch(State#state{workers=Rest});

        _ ->
            {noreply, State}
    end;

dispatch(State) ->
    {noreply, State}.

%% =========================

handle_call(_Msg, _From, State) ->
    {reply, ok, State}.

handle_info(tick, State) ->
    erlang:send_after(500, self(), tick),
    dispatch(State).
