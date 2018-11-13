%%%-------------------------------------------------------------------
%% @doc minesweeper top level supervisor.
%% @end
%%%-------------------------------------------------------------------

-module(minesweeper_sup).

-behaviour(supervisor).

%% API
-export([start_link/0]).

%% Supervisor callbacks
-export([init/1]).

-define(SERVER, ?MODULE).

%%====================================================================
%% API functions
%%====================================================================

start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

%%====================================================================
%% Supervisor callbacks
%%====================================================================

init([]) ->
  clear(),
  io:format("Type \"minesweeper:start().\" to start a game. ~n"),
  io:format("Type \"brain:start()\" to start AI. ~n"),
  SupervisorSpecs = {one_for_one, 60, 3600}, % Supervisor specs.
  ChildSpecs = {logic, {logic, start_link, []}, % Child Id and start specs.
    permanent, 1000, worker, [logic]}, % Child restart strategy, type and modules.
  {ok, {SupervisorSpecs, [ChildSpecs]}}.

clear() ->
  io:format("\e[H\e[J"),
  io:format("MINESWEEPER v1.1 ~n"),
  io:format("~n").