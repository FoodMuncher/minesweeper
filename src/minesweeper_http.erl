%%%-------------------------------------------------------------------
%%% @author joeedward
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 04. Oct 2018 11:20
%%%-------------------------------------------------------------------
-module(minesweeper_http).
-author("joeedward").

%% API
-export([init/3, content_types_provided/2, html/2]).

init(_Transport, _Req, []) ->
  {upgrade, protocol, cowboy_rest}.

content_types_provided(Req, State) ->
  {[
    {<<"text/html">>, html}
  ], Req, State}.

 html(Req, State) ->
  {Page, Req1} = cowboy_req:binding(page, Req, <<"home">>),
  {Row, Req2} = cowboy_req:qs_val(<<"row">>, Req1, <<>>),
  {Col, Req3} = cowboy_req:qs_val(<<"col">>, Req2, <<>>),
  {Coords, Req4} = cowboy_req:qs_val(<<"coords">>, Req3),
  {Pop, Req5} = cowboy_req:qs_val(<<"pop">>, Req4),
  Active = logic:active_check(),
  Body = case Page of
           <<"make">> -> make_page(Row, Col);
           _ when Active == set_up -> home_page();
           <<"home">> -> home_page();
           <<"play">> -> play_page(Coords, Pop);
           _ ->
%%             lager:log(warning, self(), "minesweeper_http received invalid page: ~p ~n", [Page]),
             home_page()
         end,
  {Body, Req5, State}.

home_page() ->
  <<"<html>
<head>
	<meta charset=\"utf-8\">
	<title>Home</title>
</head>
<body>
  <h1>Minesweeper: Home</h1>
	<h3>Choose grid size:</h3>
	<form action=\"/make\">
  Rows:<br>
  <input type=\"text\" name=\"row\">
  <br>
  Columns:<br>
  <input type=\"text\" name=\"col\">
  <br><br>
  <input type=\"submit\" value=\"Go\">
</form>
</body>
</html>">>.

make_page(RawRows, RawCols) ->
  {Rows, []} = string:to_integer(binary_to_list(RawRows)),
  {Cols, []} = string:to_integer(binary_to_list(RawCols)),
  logic:set_up(Rows, Cols),
  Board = logic:get_board(),
  [<<"<html>
<head>
	<meta charset=\"utf-8\">
	<title>Minesweeper</title>
</head>

<body>
  <h1>Minesweeper</h1>
  <form action=\"play\">">>,
  make_buttons(Board),
  <<"
  <form action=\"home\">
  <input type=\"submit\" value=\"Home\">
  </form>
</body>
<style>
.cover_button {
    background-color: #e7e7e7;
    border: 1px solid #555555;
    border-radius: 11px;
    color: black;
    padding: 9.5px 18px;
    cursor: pointer;
    float: left;
}

.cover_button:hover {
    background-color: white;
}
</style>
</html>">>].

play_page(Coords, Pop) ->

  case {Coords, Pop} of
    _ when Coords == undefined; Pop == undefined ->
      ok;
    _ ->
      {Row, T} = string:to_integer(binary_to_list(Coords)),
      [_H1|T1] = T,
      {Col, []} = string:to_integer(T1),
      case Pop of
        <<"pop">> -> logic:pop(Row, Col);
        <<"flag">> -> logic:flag(Row, Col)
      end
  end,
  timer:sleep(25),
  Board = logic:get_board(),
  [
    <<"<html>
<head>
	<meta charset=\"utf-8\">
	<title>Minesweeper</title>
</head>

<body>
  <h1>Minesweeper</h1>
  <form action=\"play\">">>,
    make_buttons(Board),
    <<"
    <form action=\"home\">
  <input type=\"submit\" value=\"Home\">
  </form>
</body>
<style>
.button {
    background-color: #4CAF50;
    border: 1px solid #555555;
    border-radius: 10px;
    color: white;
    padding: 9.5px 17px;
    cursor: pointer;
    float: left;
}

.cover_button {
    background-color: #e7e7e7;
    border: 1px solid #555555;
    border-radius: 11px;
    color: black;
    padding: 9.5px 18px;
    cursor: pointer;
    float: left;
}

.cover_button:hover {
    background-color: white;
}

.empty_button {
    background-color: #4CAF50;
    border: 1px solid #555555;
    border-radius: 10px;
    color: white;
    padding: 18px 20.5px;
    cursor: pointer;
    float: left;
}

.flag_button {
    background-color: #f44336;
    border: 1px solid #555555;
    border-radius: 10px;
    color: white;
    padding: 9.5px 18.5px;
    cursor: pointer;
    float: left;
}

.flag_button:hover {
    background-color: white;
    color: black;
}
.disabled {
    opacity: 0.6;
    cursor: not-allowed;
}
</style>
</html>">>].

%%====================================================================
%% Internal functions
%%====================================================================

make_buttons({won, Board}) -> list_to_binary([make_buttons(Board, 1, 1, <<"">>),
  <<"</form>
  <br><h3>CONGRATULATIONS!! You won :)</h3>">>]);
make_buttons({dead, Board}) -> list_to_binary([make_buttons(Board, 1, 1, <<"">>),
  <<"</form>
  <br><h3>BOOM!! You hit a mine -.-</h3>">>]);
make_buttons(Board) -> list_to_binary([make_buttons(Board, 1, 1, <<"">>),
  <<"<input type=\"radio\" name=\"pop\" value=\"pop\" checked> Pop
    <input type=\"radio\" name=\"pop\" value=\"flag\"> Flag<br>
    </form>">>]).
make_buttons([], _AccRow, _AccCol, Acc) ->
  Acc;
make_buttons([[H1|[]]|T], AccRow, AccCol, Acc) ->
  case H1 of
    b ->
      Button = <<"<button class=\"button disabled\">*</button><br><br>">>;
    c ->
      RowBin = io_lib:format("~p", [AccRow]),
      ColBin = io_lib:format("~p", [AccCol]),
      Button = [<<"<button class=\"cover_button\" name=\"coords\" type=\"submit\" value=\"">>, RowBin, <<",">>, ColBin, <<"\">?</button><br><br>">>];
    e ->
      Button = <<"<button class=\"empty_button disabled\"> </button><br><br>">>;
    f ->
      RowBin = io_lib:format("~p", [AccRow]),
      ColBin = io_lib:format("~p", [AccCol]),
      Button = [<<"<button class=\"flag_button\" name=\"coords\" type=\"submit\" value=\"">>, RowBin, <<",">>, ColBin, <<"\">f</button><br><br>">>];
    Num ->
      Image =  io_lib:format("~p", [Num]),
      Button = [<<"<button class=\"button disabled\">">>, Image, <<"</button><br><br>">>]
  end,
  make_buttons(T, AccRow + 1, 1, list_to_binary([Acc,Button]));
make_buttons([[H1|T1]|T], AccRow, AccCol, Acc) ->
  case H1 of
    b ->
      Button = <<"<button class=\"button disabled\">*</button>">>;
    c ->
      RowBin = io_lib:format("~p", [AccRow]),
      ColBin = io_lib:format("~p", [AccCol]),
      Button = [<<"<button class=\"cover_button\" name=\"coords\" type=\"submit\" value=\"">>, RowBin, <<",">>, ColBin, <<"\">?</button>">>];
    e ->
      Button = <<"<button class=\"empty_button disabled\"> </button>">>;
    f ->
      RowBin = io_lib:format("~p", [AccRow]),
      ColBin = io_lib:format("~p", [AccCol]),
      Button = [<<"<button class=\"flag_button\" name=\"coords\" type=\"submit\" value=\"">>, RowBin, <<",">>, ColBin, <<"\">f</button>">>];
    Num ->
      Image =  io_lib:format("~p", [Num]),
      Button = [<<"<button class=\"button disabled\">">>, Image, <<"</button>">>]
  end,
  make_buttons([T1|T], AccRow, AccCol + 1, list_to_binary([Acc,Button])).