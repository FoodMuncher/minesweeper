%%%-------------------------------------------------------------------
%%% @author joeedward
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 03. Oct 2018 11:09
%%%-------------------------------------------------------------------
-module(internals).
-author("joeedward").

%% API
-export([print/1, check/3, mine_locations/1]).

print([]) ->
  io:format("~n");
print([[H1|[]]|T]) ->
  output(H1),
  io:format("~n"),
  print(T);
print([[H1|T1]|T]) ->
  output(H1),
  print([T1|T]).

output(Elem) ->
  case Elem of
    b -> io:format("*");
    c -> io:format("?");
    e -> io:format(" ");
    f -> io:format("!");
    Elem when is_integer(Elem) -> io:format("~p", [Elem]);
    _ -> io:format("$")
  end.

check(Row, Col, Mines) -> check_acc(1, Row, Col, Mines, 0).
check_acc(9, _Row, _Col, _Mines, Acc) ->
  case Acc of
    0 -> e;
    _ -> Acc
  end;
check_acc(Pos, Row, Col, Mines, Acc) ->
  {RowCheck, ColCheck} =
    case Pos of
      1 -> {Row - 1, Col - 1};
      2 -> {Row - 1, Col};
      3 -> {Row - 1, Col + 1};
      4 -> {Row, Col - 1};
      5 -> {Row, Col + 1};
      6 -> {Row + 1, Col -1};
      7 -> {Row + 1, Col};
      8 -> {Row + 1, Col + 1}
    end,
  case lists:member({RowCheck, ColCheck}, Mines) of
    true -> check_acc(Pos + 1, Row, Col, Mines, Acc + 1);
    false -> check_acc(Pos + 1, Row, Col, Mines, Acc)
  end.

mine_locations(MineField) -> mine_locations(MineField, 1, 1, []).
mine_locations([], _Row, _Col, Acc) ->
  Acc;
mine_locations([[b|[]]|T], Row, Col, Acc) ->
  mine_locations(T, Row + 1, 1, [{Row, Col} | Acc]);
mine_locations([[e|[]]|T], Row, _Col, Acc) ->
  mine_locations(T, Row + 1, 1, Acc);
mine_locations([[b|Next]|T], Row, Col, Acc) ->
  mine_locations([Next|T], Row, Col + 1, [{Row, Col} | Acc]);
mine_locations([[e|Next]|T], Row, Col, Acc) ->
  mine_locations([Next|T], Row, Col + 1, Acc).