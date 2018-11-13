%%%-------------------------------------------------------------------
%%% @author joeedward
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 03. Oct 2018 10:59
%%%-------------------------------------------------------------------
-module(minesweeper).
-author("joeedward").

%% API
-export([start/0]).

start() ->
  clear(),
  io:format("Choose board size:~n"),
  io:format("Please enter how many rows you would like. ~n"),
  Rows = input_num('rows>'),
  Cols = input_num('columns>'),
  clear(),
  logic:set_up(Rows, Cols),
  Board = logic:get_board(),
  internals:print(Board),
  loop().

loop() ->
  io:format("Choose row:~n"),
  Row = input_num('row>'),
  io:format("Choose column:~n"),
  Col = input_num('column>'),
  io:format("pop or flag:~n"),
  Opt = input_pop(),
  case Opt of
    pop -> logic:pop(Row, Col);
    flag -> logic:flag(Row, Col)
  end,
  timer:sleep(25),
  case logic:get_board() of
    {dead, Board} ->
      clear(),
      internals:print(Board),
      io:format("BOOM!! You hit a mine -.- ~n"),
      io:format("Type \"minesweeper:start()\" to start a new game. ~n");
    {won, Board} ->
      clear(),
      internals:print(Board),
      io:format("CONGRATULATIONS!! You won :) ~n"),
      io:format("Type \"minesweeper:start()\" to start a new game. ~n");
    Board ->
      clear(),
      internals:print(Board),
      loop()
  end.

%%%===================================================================
%%% Internal functions
%%%===================================================================

input_num(Name) ->
  case io:read(Name) of
    {ok, Rows} when is_integer(Rows) ->
      Rows;
    _ ->
      io:format("Please type only one integer.~n"),
      input_num(Name)
  end.

input_pop() ->
  case io:read('pop or flag>') of
    {ok, pop} -> pop;
    {ok, flag} -> flag;
    _ ->
      io:format("Please type pop or flag.~n"),
      input_pop()
  end.

clear() ->
  io:format("\e[H\e[J"),
  io:format("MINESWEEPER v1.1 ~n"),
  io:format("~n").
