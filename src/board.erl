%%%-------------------------------------------------------------------
%%% @author joeedward
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 02. Oct 2018 16:14
%%%-------------------------------------------------------------------
-module(board).
-author("joeedward").

-define(PROB, 0.125).

%% API
-export([create_background/2, create_board/2]).

create_board(Rows, Cols) -> create_board(Rows, Cols, 1, []).
create_board(Rows, Cols, AccRow, Acc) when Rows == AccRow ->
  [board_row(Cols, 1, []) | Acc];
create_board(Rows, Cols, AccRow, Acc) ->
  create_board(Rows, Cols, AccRow + 1, [board_row(Cols, 1, []) | Acc]).

board_row(Cols, AccCol, Acc) when Cols == AccCol ->
  Acc ++ [c];
board_row(Cols, AccCol, Acc) ->
  board_row(Cols, AccCol + 1, Acc ++ [c]).

create_background(Rows, Cols) ->
  Minefield = create_mines(Rows, Cols),
  Mines = internals:mine_locations(Minefield),
  create_field(Minefield, Mines).

create_mines(Rows, Cols) -> create_mines_acc(Rows, Cols, 1, []).
create_mines_acc(Rows, Cols, AccRow, Acc) when Rows + 1 == AccRow ->
  case lists:member(b, lists:concat(Acc)) of
    true ->
      Acc;
    false -> create_mines(Rows, Cols)
  end;
create_mines_acc(Rows, Cols, 1, []) ->
  create_mines_acc(Rows, Cols, 2, [create_mines_row(Cols, 1, [])]);
create_mines_acc(Rows, Cols, AccRow, Acc) ->
  create_mines_acc(Rows, Cols, AccRow + 1, [create_mines_row(Cols, 1, []) | Acc]).

create_mines_row(Cols, AccCol, Acc) when AccCol == Cols + 1 ->
  Acc;
create_mines_row(Cols, AccCol, Acc) ->
  case rand:uniform() > ?PROB of
    true ->
      create_mines_row(Cols, AccCol + 1, [e|Acc]);
    false ->
      create_mines_row(Cols, AccCol + 1, [b|Acc])
  end.

create_field(Minefield, Mines) -> create_field_acc(Minefield, Mines, 1, []).
create_field_acc([], _Mines, _Row, Acc) ->
  lists:reverse(Acc);
create_field_acc([H|T], Mines, Row, Acc) ->
  create_field_acc(T, Mines, Row + 1, [row(H, Mines, Row, 1, [])|Acc]).

row([], _Mines, _Row, _Col, Acc) ->
  lists:reverse(Acc);
row([e|T], Mines, Row, Col, Acc) ->
  row(T, Mines, Row, Col + 1, [internals:check(Row, Col, Mines)|Acc]);
row([b|T], Mines, Row, Col, Acc) ->
  row(T, Mines, Row, Col + 1, [b|Acc]).