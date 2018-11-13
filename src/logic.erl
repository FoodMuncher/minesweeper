%%%-------------------------------------------------------------------
%%% @author joeedward
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 03. Oct 2018 12:06
%%%-------------------------------------------------------------------
-module(logic).
-author("joeedward").

-behaviour(gen_server).

%%======================================================
%% 1. list of popped squares so cant pop same twice.
%% 2. Remove catch by using cases.
%%======================================================

%% API
-export([start_link/0, set_up/2, pop/2, get_board/0, flag/2, active_check/0]).

%% gen_server callbacks
-export([init/1,
  handle_call/3,
  handle_cast/2,
  handle_info/2,
  terminate/2,
  code_change/3]).

-define(SERVER, ?MODULE).

-record(state, {
  stage          :: set_up | playing,
  background     :: list(),
  board          :: list(),
  popped         :: [tuple()]
}).

%%%===================================================================
%%% API
%%%===================================================================

start_link() ->
  gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

set_up(Rows, Cols) ->
  gen_server:cast(?MODULE, {set_up, Rows, Cols}).

pop(Row, Col) ->
  gen_server:cast(?MODULE, {pop, Row, Col}).

get_board() ->
  gen_server:call(?MODULE, get_board).

flag(Row, Col) ->
  gen_server:cast(?MODULE, {flag, Row, Col}).

active_check() ->
  gen_server:call(?MODULE, active_check).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

init([]) ->
  {ok, #state{stage = set_up}}.

handle_call(get_board, _From, S = #state{board = Board}) ->
  NewBoard =
    case check_won(Board) of
      dead -> Board;
      won -> {won, Board};
      active -> Board
    end,
  {reply, NewBoard, S};
handle_call(active_check, _From, S = #state{stage = Stage}) ->
  {reply, Stage, S};
handle_call(_Request, _From, State) ->
  {reply, ok, State}.

handle_cast({set_up, Rows, Cols}, S) ->
  Background = board:create_background(Rows, Cols),
  Board = board:create_board(Rows, Cols),
  {noreply, S#state{stage = active, background = Background, board = Board, popped = []}};
handle_cast({pop, Row, Col}, S = #state{background = Background, board = Board, popped = Popped}) ->
  case (catch(elem(Background, Row, Col))) of
    b ->
      NewBoard = {dead, update_board(Board, Row, Col, b)};
    e ->
      NewBoard = update_board(Board, Row, Col, e),
      gen_server:cast(?MODULE, {pop_around, 1, Row, Col});
    Elem when is_integer(Elem) ->
      NewBoard = update_board(Board, Row, Col, Elem);
    _ ->
      NewBoard = Board
  end,
  {noreply, S#state{board = NewBoard, popped = [{Row, Col}|Popped]}};
handle_cast({pop_around, 9, _InitRow, _InitCol}, S) ->
  {noreply, S};
handle_cast({pop_around, Pos, InitRow, InitCol}, S = #state{background = Background, board = Board, popped = Popped}) ->
  {Row, Col} = pos(Pos, InitRow, InitCol),
  PopCheck = lists:member({Row, Col}, Popped),
  NewBoard =
    case (catch(elem(Background, Row, Col))) of
      _ when PopCheck == true ->
        gen_server:cast(?MODULE, {pop_around, Pos + 1, InitRow, InitCol}),
        NewPopped = Popped,
        Board;
      e ->
        gen_server:cast(?MODULE, {pop, Row, Col}),
        gen_server:cast(?MODULE, {pop_around, Pos + 1, InitRow, InitCol}),
        NewPopped = [{Row, Col} | Popped],
        update_board(Board, Row, Col, e);
      b ->
        gen_server:cast(?MODULE, {pop_around, Pos + 1, InitRow, InitCol}),
        NewPopped = [{Row, Col} | Popped],
        Board;
      Elem when is_integer(Elem) ->
        gen_server:cast(?MODULE, {pop_around, Pos + 1, InitRow, InitCol}),
        NewPopped = [{Row, Col} | Popped],
        update_board(Board, Row, Col, Elem);
      _ ->
        gen_server:cast(?MODULE, {pop_around, Pos + 1, InitRow, InitCol}),
        NewPopped = [{Row, Col} | Popped],
        Board
    end,
  {noreply, S#state{board = NewBoard, popped = NewPopped}};
handle_cast({flag, Row, Col}, S = #state{board = Board}) ->
  {noreply, S#state{board = update_board(Board, Row, Col, f)}};
handle_cast(_Request, State) ->
  {noreply, State}.

handle_info(_Info, State) ->
  {noreply, State}.

terminate(_Reason, _State) ->
  ok.

code_change(_OldVsn, State, _Extra) ->
  {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================

pos(Pos, Row, Col) ->
  case Pos of
    1 -> {Row - 1, Col - 1};
    2 -> {Row - 1, Col};
    3 -> {Row - 1, Col + 1};
    4 -> {Row, Col - 1};
    5 -> {Row, Col + 1};
    6 -> {Row + 1, Col -1};
    7 -> {Row + 1, Col};
    8 -> {Row + 1, Col + 1}
  end.

elem(Board, Row, Col) ->
  Line = lists:nth(Row, Board),
  lists:nth(Col, Line).

update_board({dead, Board}, _Row, _Col, _Elem) ->
  Board;
update_board(Board, Row, Col, Elem) ->
  Line = lists:nth(Row, Board),
  NewLine =
    lists:flatten([lists:sublist(Line, Col - 1), Elem, lists:nthtail(Col, Line)]),
  lists:sublist(Board, Row - 1) ++ [NewLine] ++ lists:nthtail(Row, Board).

check_won({dead, _Board}) ->
  dead;
check_won([]) ->
  won;
check_won([H|T]) ->
  case lists:member(c, H) of
    true ->
      active;
    false ->
      check_won(T)
  end.