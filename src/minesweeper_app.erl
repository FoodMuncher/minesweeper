%%%-------------------------------------------------------------------
%% @doc minesweeper public API
%% @end
%%%-------------------------------------------------------------------

-module(minesweeper_app).

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

%%====================================================================
%% API
%%====================================================================

start(_StartType, _StartArgs) ->
  Dispatch = cowboy_router:compile([
    {'_',[
      {"/[:page]", minesweeper_http, []}
    ]}
  ]),
  cowboy:start_http(kv_http_listener, 20, [{port, 1234}],
    [{env, [{dispatch, Dispatch}]}]
  ),
  minesweeper_sup:start_link().

%%--------------------------------------------------------------------
stop(_State) ->
  ok.

%%====================================================================
%% Internal functions
%%====================================================================
