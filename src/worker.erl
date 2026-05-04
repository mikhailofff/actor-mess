-module(worker).
-behaviour(gen_server).

-export([start_link/0]).
-export([
    init/1,
    handle_cast/2,
    handle_call/3,
    handle_info/2,
    terminate/2,
    code_change/3
]).

start_link() ->
    gen_server:start_link(?MODULE, [], []).

init([]) ->
    gen_server:cast({global, job_queue}, {worker_ready, self()}),
    io:format("Worker started: ~p~n", [self()]),
    {ok, #{}}.

handle_cast({process, Id, Task, Retry}, State) ->
    Result = process_task(Task),

    case Result of
        {ok, Data} ->
            io:format("SUCCESS ~p~n", [Data]),
            gen_server:cast({global, metrics_server}, success);

        {error, Err} ->
            io:format("FAIL ~p~n", [Err]),
            gen_server:cast({global, metrics_server}, failure),
            retry_manager:retry(Id, Task, Retry)
    end,

    gen_server:cast({global, job_queue}, {worker_ready, self()}),
    {noreply, State}.

handle_call(_Msg, _From, State) ->
    {reply, ok, State}.

handle_info(_Info, State) ->
    {noreply, State}.

code_change(_, State, _) ->
    {ok, State}.

ensure_http() ->
    application:ensure_all_started(inets).

process_task({http, Url}) ->
    ensure_http(),

    case httpc:request(get, {Url, []}, [{timeout, 2000}], []) of

        {ok, {{_, Code, _}, Headers, Body}} when Code >= 200, Code < 300 ->
            {ok, #{url => Url, status => Code, headers => Headers, body => Body}};

        {ok, {{_, Code, _}, Headers, Body}} when Code >= 300 ->
            {error, #{url => Url, status => Code, headers => Headers, body => Body}};

        {error, Reason} ->
            {error, #{url => Url, reason => Reason}}
    end.

terminate(Reason, _) ->
    io:format("Worker died: ~p~n", [Reason]).
