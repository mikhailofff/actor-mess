-module(metrics_server).
-behaviour(gen_server).

-export([start_link/0, success/0, failure/0, get/0]).
-export([init/1, handle_cast/2, handle_call/3]).

-record(state, {ok=0, fail=0}).

start_link() ->
    gen_server:start_link({global, ?MODULE}, ?MODULE, [], []).

success() ->
    gen_server:cast({global, ?MODULE}, success).

failure() ->
    gen_server:cast({global, ?MODULE}, failure).

get() ->
    gen_server:call({global, ?MODULE}, get).

init([]) ->
    {ok, #state{}}.

handle_cast(success, S=#state{ok=Ok}) ->
    {noreply, S#state{ok=Ok+1}};

handle_cast(failure, S=#state{fail=F}) ->
    {noreply, S#state{fail=F+1}}.

handle_call(get, _, S) ->
    {reply, S, S}.
