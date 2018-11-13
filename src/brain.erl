%%%-------------------------------------------------------------------
%%% @author joeedward
%%% @copyright (C) 2018, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 17. Oct 2018 15:43
%%%-------------------------------------------------------------------
-module(brain).
-author("joeedward").

%% API
-export([start/0, advanced_decision_maker/1, remove_finished/1]).

%%====================================================================
%% Advanced AI Possibilities:
%%   plot all mine possibilities then go from there.
%%   Probabilities?
%% Possible method:
%%   See what th blank can possible be. i.e 3, bomb or 4??? then use this information and plot out all the possible bomb places.
%%   Do this in sync and if two possibilities land on the same conclusion then it must be that conclusion.
%%=====================================================================

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
  first_loop(Rows, Cols).

start(Rows, Cols) ->
  clear(),
  logic:set_up(Rows, Cols),
  Board = logic:get_board(),
  internals:print(Board),
  first_loop(Rows, Cols).


first_loop(MaxRow, MaxCol) ->
  logic:pop(1,1),
  case logic:get_board() of
    {dead, Board} ->
      clear(),
      internals:print(Board),
      io:format("BOOM!! You hit a mine -.- ~n"),
      io:format("Type \"brain:start()\" to start AI again. ~n");
    Board ->
      clear(),
      internals:print(Board),
      loop(MaxRow, MaxCol, 1)
  end.
loop(MaxRow, MaxCol, Corners) ->
  Board = logic:get_board(),
  {Opt, DecRow, DecCol} = decide_pop_or_flag(Board, MaxRow, MaxRow),
  case Opt of
    pop ->
      {Opt, Row, Col} = find_blank(Board, Opt, DecRow, DecCol, MaxRow, MaxCol),
      logic:pop(Row, Col);
    flag ->
      {Opt, Row, Col} = find_blank(Board, Opt, DecRow, DecCol, MaxRow, MaxCol),
      logic:flag(Row, Col);
    no ->
      timer:sleep(2500),
      case Corners of
        1 ->
          case elem(Board, MaxRow, 1) of
            c -> logic:pop(MaxRow, 1);
            _ -> loop(MaxRow, MaxCol, 2)
          end;
        2 ->
          case elem(Board, MaxRow, MaxCol) of
            c -> logic:pop(MaxRow, MaxCol);
            _ -> loop(MaxRow, MaxCol, 3)
          end;
        3 ->
          case elem(Board, 1, MaxCol) of
            c -> logic:pop(1, MaxCol);
            _ -> loop(MaxRow, MaxCol, 4)
          end;
        4 -> ok
      end
  end,
%%  timer:sleep(25),
  case logic:get_board() of
    {dead, NewBoard} ->
      clear(),
      internals:print(NewBoard),
      io:format("BOOM!! You hit a mine -.- ~n"),
      io:format("Type \"brain:start()\" to start AI again. ~n");
    {won, NewBoard} ->
      clear(),
      internals:print(NewBoard),
      io:format("CONGRATULATIONS!! You won :) ~n"),
      io:format("Type \"brain:start()\" to start AI again. ~n"),
      timer:sleep(500),
      start(MaxRow, MaxCol);
    NewBoard when (Opt == no) and (Corners == 4) ->
      clear(),
      internals:print(NewBoard),
      io:format("~n~n~n~n"),
      io:format("I DONT KNOW WHAT TO DO ?????????~n"),
      io:format("Reason: ~p ~p ~p ~n", [Opt, DecRow, DecCol]),
      io:format("Information: ~p", [create_digit_info_list(NewBoard, MaxRow, MaxCol)]);
    NewBoard when Opt == no ->
      clear(),
      internals:print(NewBoard),
      loop(MaxRow, MaxCol, Corners  + 1);
    NewBoard ->
      clear(),
      internals:print(NewBoard),
      loop(MaxRow, MaxCol, Corners)
  end.

%%%===================================================================
%%% AI functions
%%%===================================================================

decide_pop_or_flag(Board, MaxRow, MaxCol) ->
  DigitInfoList = create_digit_info_list(Board, MaxRow, MaxCol),
  decision_maker(DigitInfoList).

create_digit_info_list(Board, MaxRow, MaxCol) -> create_digit_info_list(Board, MaxRow, MaxCol, 1, 1, []).
create_digit_info_list(Board, MaxRow, MaxCol, MaxRow, MaxCol, New) ->
  lists:flatten([check_around(bot_right, Board, MaxRow, MaxCol)|New]);
create_digit_info_list(Board, MaxRow, MaxCol, MaxRow, 1, New) ->
  create_digit_info_list(Board, MaxRow, MaxCol, MaxRow, 2, [check_around(bot_left, Board, MaxRow, 1)|New]);
create_digit_info_list(Board, MaxRow, MaxCol, 1, MaxCol, New) ->
  create_digit_info_list(Board, MaxRow, MaxCol, 2, 1, [check_around(top_right, Board, 1, MaxCol)|New]);
create_digit_info_list(Board, MaxRow, MaxCol, 1, 1, New) ->
  create_digit_info_list(Board, MaxRow, MaxCol, 1, 2, [check_around(top_left, Board, 1, 1)|New]);
create_digit_info_list(Board, MaxRow, MaxCol, 1, Col, New) ->
  create_digit_info_list(Board, MaxRow, MaxCol, 1, Col + 1, [check_around(top, Board, 1, Col)|New]);
create_digit_info_list(Board, MaxRow, MaxCol, MaxRow, Col, New) ->
  create_digit_info_list(Board, MaxRow, MaxCol, MaxRow, Col + 1, [check_around(bot, Board, MaxRow, Col)|New]);
create_digit_info_list(Board, MaxRow, MaxCol, Row, MaxCol, New) ->
  create_digit_info_list(Board, MaxRow, MaxCol, Row + 1, 1, [check_around(right, Board, Row, MaxCol)|New]);
create_digit_info_list(Board, MaxRow, MaxCol, Row, 1, New) ->
  create_digit_info_list(Board, MaxRow, MaxCol, Row, 2, [check_around(left, Board, Row, 1)|New]);
create_digit_info_list(Board, MaxRow, MaxCol, Row, Col, New) ->
  create_digit_info_list(Board, MaxRow, MaxCol, Row, Col + 1, [check_around(mid, Board, Row, Col)|New]).

check_around(bot_right, Board, Row, Col) ->
  case elem(Board, Row, Col) of
    c -> [];
    f -> [];
    e -> [];
    Num when is_integer(Num) ->
      Elem = Num,
      {Flags1, Blanks1} =
        case elem(Board, Row, Col - 1) of
          c -> {0, 1};
          f -> {1, 0};
          _ -> {0, 0}
        end,
      {Flags2, Blanks2} =
        case elem(Board, Row - 1, Col - 1) of
          c -> {Flags1, Blanks1 + 1};
          f -> {Flags1 + 1, Blanks1};
          _ -> {Flags1, Blanks1}
        end,
      {Flags, Blanks} =
        case elem(Board, Row - 1, Col) of
          c -> {Flags2, Blanks2 + 1};
          f -> {Flags2 + 1, Blanks2};
          _ -> {Flags2, Blanks2}
        end,
      {{Row, Col}, {Elem, Flags, Blanks}}
  end;
check_around(bot_left, Board, Row, Col) ->
  case elem(Board, Row, Col) of
    c -> [];
    f -> [];
    e -> [];
    Num when is_integer(Num) ->
      Elem = Num,
      {Flags1, Blanks1} =
        case elem(Board, Row - 1, Col) of
          c -> {0, 1};
          f -> {1, 0};
          _ -> {0, 0}
        end,
      {Flags2, Blanks2} =
        case elem(Board, Row - 1, Col + 1) of
          c -> {Flags1, Blanks1 + 1};
          f -> {Flags1 + 1, Blanks1};
          _ -> {Flags1, Blanks1}
        end,
      {Flags, Blanks} =
        case elem(Board, Row, Col + 1) of
          c -> {Flags2, Blanks2 + 1};
          f -> {Flags2 + 1, Blanks2};
          _ -> {Flags2, Blanks2}
        end,
      {{Row, Col}, {Elem, Flags, Blanks}}
  end;
check_around(top_right, Board, Row, Col) ->
  case elem(Board, Row, Col) of
    c -> [];
    f -> [];
    e -> [];
    Num when is_integer(Num) ->
      Elem = Num,
      {Flags1, Blanks1} =
        case elem(Board, Row, Col - 1) of
          c -> {0, 1};
          f -> {1, 0};
          _ -> {0, 0}
        end,
      {Flags2, Blanks2} =
        case elem(Board, Row + 1, Col - 1) of
          c -> {Flags1, Blanks1 + 1};
          f -> {Flags1 + 1, Blanks1};
          _ -> {Flags1, Blanks1}
        end,
      {Flags, Blanks} =
        case elem(Board, Row + 1, Col) of
          c -> {Flags2, Blanks2 + 1};
          f -> {Flags2 + 1, Blanks2};
          _ -> {Flags2, Blanks2}
        end,
      {{Row, Col}, {Elem, Flags, Blanks}}
  end;
check_around(top_left, Board, Row, Col) ->
  case elem(Board, Row, Col) of
    c -> [];
    f -> [];
    e -> [];
    Num when is_integer(Num) ->
      Elem = Num,
      {Flags1, Blanks1} =
        case elem(Board, Row + 1, Col) of
          c -> {0, 1};
          f -> {1, 0};
          _ -> {0, 0}
        end,
      {Flags2, Blanks2} =
        case elem(Board, Row + 1, Col + 1) of
          c -> {Flags1, Blanks1 + 1};
          f -> {Flags1 + 1, Blanks1};
          _ -> {Flags1, Blanks1}
        end,
      {Flags, Blanks} =
        case elem(Board, Row, Col + 1) of
          c -> {Flags2, Blanks2 + 1};
          f -> {Flags2 + 1, Blanks2};
          _ -> {Flags2, Blanks2}
        end,
      {{Row, Col}, {Elem, Flags, Blanks}}
  end;
check_around(top, Board, Row, Col) ->
  case elem(Board, Row, Col) of
    c -> [];
    f -> [];
    e -> [];
    Num when is_integer(Num) ->
      Elem = Num,
      {Flags1, Blanks1} =
        case elem(Board, Row, Col - 1) of
          c -> {0, 1};
          f -> {1, 0};
          _ -> {0, 0}
        end,
      {Flags2, Blanks2} =
        case elem(Board, Row, Col + 1) of
          c -> {Flags1, Blanks1 + 1};
          f -> {Flags1 + 1, Blanks1};
          _ -> {Flags1, Blanks1}
        end,
      {Flags3, Blanks3} =
        case elem(Board, Row + 1, Col + 1) of
          c -> {Flags2, Blanks2 + 1};
          f -> {Flags2 + 1, Blanks2};
          _ -> {Flags2, Blanks2}
        end,
      {Flags4, Blanks4} =
        case elem(Board, Row + 1, Col) of
          c -> {Flags3, Blanks3 + 1};
          f -> {Flags3 + 1, Blanks3};
          _ -> {Flags3, Blanks3}
        end,
      {Flags, Blanks} =
        case elem(Board, Row + 1, Col - 1) of
          c -> {Flags4, Blanks4 + 1};
          f -> {Flags4 + 1, Blanks4};
          _ -> {Flags4, Blanks4}
        end,
      {{Row, Col}, {Elem, Flags, Blanks}}
  end;
check_around(bot, Board, Row, Col) ->
  case elem(Board, Row, Col) of
    c -> [];
    f -> [];
    e -> [];
    Num when is_integer(Num) ->
      Elem = Num,
      {Flags1, Blanks1} =
        case elem(Board, Row, Col - 1) of
          c -> {0, 1};
          f -> {1, 0};
          _ -> {0, 0}
        end,
      {Flags2, Blanks2} =
        case elem(Board, Row - 1, Col - 1) of
          c -> {Flags1, Blanks1 + 1};
          f -> {Flags1 + 1, Blanks1};
          _ -> {Flags1, Blanks1}
        end,
      {Flags3, Blanks3} =
        case elem(Board, Row - 1, Col) of
          c -> {Flags2, Blanks2 + 1};
          f -> {Flags2 + 1, Blanks2};
          _ -> {Flags2, Blanks2}
        end,
      {Flags4, Blanks4} =
        case elem(Board, Row - 1, Col + 1) of
          c -> {Flags3, Blanks3 + 1};
          f -> {Flags3 + 1, Blanks3};
          _ -> {Flags3, Blanks3}
        end,
      {Flags, Blanks} =
        case elem(Board, Row, Col + 1) of
          c -> {Flags4, Blanks4 + 1};
          f -> {Flags4 + 1, Blanks4};
          _ -> {Flags4, Blanks4}
        end,
      {{Row, Col}, {Elem, Flags, Blanks}}
  end;
check_around(right, Board, Row, Col) ->
  case elem(Board, Row, Col) of
    c -> [];
    f -> [];
    e -> [];
    Num when is_integer(Num) ->
      Elem = Num,
      {Flags1, Blanks1} =
        case elem(Board, Row, Col - 1) of
          c -> {0, 1};
          f -> {1, 0};
          _ -> {0, 0}
        end,
      {Flags2, Blanks2} =
        case elem(Board, Row - 1, Col - 1) of
          c -> {Flags1, Blanks1 + 1};
          f -> {Flags1 + 1, Blanks1};
          _ -> {Flags1, Blanks1}
        end,
      {Flags3, Blanks3} =
        case elem(Board, Row - 1, Col) of
          c -> {Flags2, Blanks2 + 1};
          f -> {Flags2 + 1, Blanks2};
          _ -> {Flags2, Blanks2}
        end,
      {Flags4, Blanks4} =
        case elem(Board, Row + 1, Col) of
          c -> {Flags3, Blanks3 + 1};
          f -> {Flags3 + 1, Blanks3};
          _ -> {Flags3, Blanks3}
        end,
      {Flags, Blanks} =
        case elem(Board, Row + 1, Col - 1) of
          c -> {Flags4, Blanks4 + 1};
          f -> {Flags4 + 1, Blanks4};
          _ -> {Flags4, Blanks4}
        end,
      {{Row, Col}, {Elem, Flags, Blanks}}
  end;
check_around(left, Board, Row, Col) ->
  case elem(Board, Row, Col) of
    c -> [];
    f -> [];
    e -> [];
    Num when is_integer(Num) ->
      Elem = Num,
      {Flags1, Blanks1} =
        case elem(Board, Row - 1, Col) of
          c -> {0, 1};
          f -> {1, 0};
          _ -> {0, 0}
        end,
      {Flags2, Blanks2} =
        case elem(Board, Row - 1, Col + 1) of
          c -> {Flags1, Blanks1 + 1};
          f -> {Flags1 + 1, Blanks1};
          _ -> {Flags1, Blanks1}
        end,
      {Flags3, Blanks3} =
        case elem(Board, Row, Col + 1) of
          c -> {Flags2, Blanks2 + 1};
          f -> {Flags2 + 1, Blanks2};
          _ -> {Flags2, Blanks2}
        end,
      {Flags4, Blanks4} =
        case elem(Board, Row + 1, Col + 1) of
          c -> {Flags3, Blanks3 + 1};
          f -> {Flags3 + 1, Blanks3};
          _ -> {Flags3, Blanks3}
        end,
      {Flags, Blanks} =
        case elem(Board, Row + 1, Col) of
          c -> {Flags4, Blanks4 + 1};
          f -> {Flags4 + 1, Blanks4};
          _ -> {Flags4, Blanks4}
        end,
      {{Row, Col}, {Elem, Flags, Blanks}}
  end;
check_around(mid, Board, Row, Col) ->
  case elem(Board, Row, Col) of
    c -> [];
    f -> [];
    e -> [];
    Num when is_integer(Num) ->
      Elem = Num,
      {Flags1, Blanks1} =
        case elem(Board, Row, Col - 1) of
          c -> {0, 1};
          f -> {1, 0};
          _ -> {0, 0}
        end,
      {Flags2, Blanks2} =
        case elem(Board, Row - 1, Col - 1) of
          c -> {Flags1, Blanks1 + 1};
          f -> {Flags1 + 1, Blanks1};
          _ -> {Flags1, Blanks1}
        end,
      {Flags3, Blanks3} =
        case elem(Board, Row - 1, Col) of
          c -> {Flags2, Blanks2 + 1};
          f -> {Flags2 + 1, Blanks2};
          _ -> {Flags2, Blanks2}
        end,
      {Flags4, Blanks4} =
        case elem(Board, Row - 1, Col + 1) of
          c -> {Flags3, Blanks3 + 1};
          f -> {Flags3 + 1, Blanks3};
          _ -> {Flags3, Blanks3}
        end,
      {Flags5, Blanks5} =
        case elem(Board, Row, Col + 1) of
          c -> {Flags4, Blanks4 + 1};
          f -> {Flags4 + 1, Blanks4};
          _ -> {Flags4, Blanks4}
        end,
      {Flags6, Blanks6} =
        case elem(Board, Row + 1, Col + 1) of
          c -> {Flags5, Blanks5 + 1};
          f -> {Flags5 + 1, Blanks5};
          _ -> {Flags5, Blanks5}
        end,
      {Flags7, Blanks7} =
        case elem(Board, Row + 1, Col) of
          c -> {Flags6, Blanks6 + 1};
          f -> {Flags6 + 1, Blanks6};
          _ -> {Flags6, Blanks6}
        end,
      {Flags, Blanks} =
        case elem(Board, Row + 1, Col - 1) of
          c -> {Flags7, Blanks7 + 1};
          f -> {Flags7 + 1, Blanks7};
          _ -> {Flags7, Blanks7}
        end,
      {{Row, Col}, {Elem, Flags, Blanks}}
  end.

decision_maker([]) ->
  {no, decision, made};
decision_maker([H|T]) ->
  {{Row, Col}, {Num, Flags, Blanks}} = H,
  if
    (Num - Flags == Blanks) and (Blanks > 0)  -> {flag, Row, Col};
    (Num == Flags) and (Blanks > 0) -> {pop, Row, Col};
    true -> decision_maker(T)
  end.

find_blank(Board, Opt, Row, Col, MaxRow, MaxCol) ->
    case {Row, Col} of
      {1,1} -> %% Top left.
        case check_right(Board, Row, Col) of
          nope ->
            case check_down_right(Board, Row, Col) of
              nope ->
                case check_down(Board, Row, Col) of
                  nope -> {no, Row, Col};
                  {OptRow, OptCol} -> {Opt, OptRow, OptCol}
                end;
              {OptRow, OptCol} -> {Opt, OptRow, OptCol}
            end;
          {OptRow, OptCol} -> {Opt, OptRow, OptCol}
        end;
      {1, MaxCol} -> %% Top Right
        case check_left(Board, Row, Col) of
          nope ->
            case check_down(Board, Row, Col) of
              nope ->
                case check_down_left(Board, Row, Col) of
                  nope -> {no, Row, Col};
                  {OptRow, OptCol} -> {Opt, OptRow, OptCol}
                end;
              {OptRow, OptCol} -> {Opt, OptRow, OptCol}
            end;
          {OptRow, OptCol} -> {Opt, OptRow, OptCol}
        end;
      {MaxRow, 1} -> %% Bottom Left
        case check_up(Board, Row, Col) of
          nope ->
            case check_up_right(Board, Row, Col) of
              nope ->
                case check_right(Board, Row, Col) of
                  nope -> {no, Row, Col};
                  {OptRow, OptCol} -> {Opt, OptRow, OptCol}
                end;
              {OptRow, OptCol} -> {Opt, OptRow, OptCol}
            end;
          {OptRow, OptCol} -> {Opt, OptRow, OptCol}
        end;
      {MaxRow, MaxCol} -> %% Bottom Right
        case check_left(Board, Row, Col) of
          nope ->
            case check_up_left(Board, Row, Col) of
              nope ->
                case check_up(Board, Row, Col) of
                  nope -> {no, Row, Col};
                  {OptRow, OptCol} -> {Opt, OptRow, OptCol}
                end;
              {OptRow, OptCol} -> {Opt, OptRow, OptCol}
            end;
          {OptRow, OptCol} -> {Opt, OptRow, OptCol}
        end;
      {1, Col} -> %% Top
        case check_left(Board, Row, Col) of
          nope ->
            case check_right(Board, Row, Col) of
              nope ->
                case check_down_right(Board, Row, Col) of
                  nope ->
                    case check_down(Board, Row, Col) of
                      nope ->
                        case check_down_left(Board, Row, Col) of
                          nope -> {no, Row, Col};
                          {OptRow, OptCol} -> {Opt, OptRow, OptCol}
                        end;
                      {OptRow, OptCol} -> {Opt, OptRow, OptCol}
                    end;
                  {OptRow, OptCol} -> {Opt, OptRow, OptCol}
                end;
              {OptRow, OptCol} -> {Opt, OptRow, OptCol}
            end;
          {OptRow, OptCol} -> {Opt, OptRow, OptCol}
        end;
      {MaxRow, Col} -> %% Bot
        case check_left(Board, Row, Col) of
          nope ->
            case check_up_left(Board, Row, Col) of
              nope ->
                case check_up(Board, Row, Col) of
                  nope ->
                    case check_up_right(Board, Row, Col) of
                      nope ->
                        case check_right(Board, Row, Col) of
                          nope -> {no, Row, Col};
                          {OptRow, OptCol} -> {Opt, OptRow, OptCol}
                        end;
                      {OptRow, OptCol} -> {Opt, OptRow, OptCol}
                    end;
                  {OptRow, OptCol} -> {Opt, OptRow, OptCol}
                end;
              {OptRow, OptCol} -> {Opt, OptRow, OptCol}
            end;
          {OptRow, OptCol} -> {Opt, OptRow, OptCol}
        end;
      {Row, 1} -> %% Left
        case check_up(Board, Row, Col) of
          nope ->
            case check_up_right(Board, Row, Col) of
              nope ->
                case check_right(Board, Row, Col) of
                  nope ->
                    case check_down_right(Board, Row, Col) of
                      nope ->
                        case check_down(Board, Row, Col) of
                          nope -> {no, Row, Col};
                          {OptRow, OptCol} -> {Opt, OptRow, OptCol}
                        end;
                      {OptRow, OptCol} -> {Opt, OptRow, OptCol}
                    end;
                  {OptRow, OptCol} -> {Opt, OptRow, OptCol}
                end;
              {OptRow, OptCol} -> {Opt, OptRow, OptCol}
            end;
          {OptRow, OptCol} -> {Opt, OptRow, OptCol}
        end;
      {Row, MaxCol} -> %% Right
        case check_left(Board, Row, Col) of
          nope ->
            case check_up_left(Board, Row, Col) of
              nope ->
                case check_up(Board, Row, Col) of
                  nope ->
                    case check_down(Board, Row, Col) of
                      nope ->
                        case check_down_left(Board, Row, Col) of
                          nope -> {no, Row, Col};
                          {OptRow, OptCol} -> {Opt, OptRow, OptCol}
                        end;
                      {OptRow, OptCol} -> {Opt, OptRow, OptCol}
                    end;
                  {OptRow, OptCol} -> {Opt, OptRow, OptCol}
                end;
              {OptRow, OptCol} -> {Opt, OptRow, OptCol}
            end;
          {OptRow, OptCol} -> {Opt, OptRow, OptCol}
        end;
      {Row, Col} -> %% Mid
        case check_left(Board, Row, Col) of
          nope ->
            case check_up_left(Board, Row, Col) of
              nope ->
                case check_up(Board, Row, Col) of
                  nope ->
                    case check_up_right(Board, Row, Col) of
                      nope ->
                        case check_right(Board, Row, Col) of
                          nope ->
                            case check_down_right(Board, Row, Col) of
                              nope ->
                                case check_down(Board, Row, Col) of
                                  nope ->
                                    case check_down_left(Board, Row, Col) of
                                      nope -> {no, Row, Col};
                                      {OptRow, OptCol} -> {Opt, OptRow, OptCol}
                                    end;
                                  {OptRow, OptCol} -> {Opt, OptRow, OptCol}
                                end;
                              {OptRow, OptCol} -> {Opt, OptRow, OptCol}
                            end;
                          {OptRow, OptCol} -> {Opt, OptRow, OptCol}
                        end;
                      {OptRow, OptCol} -> {Opt, OptRow, OptCol}
                    end;
                  {OptRow, OptCol} -> {Opt, OptRow, OptCol}
                end;
              {OptRow, OptCol} -> {Opt, OptRow, OptCol}
            end;
          {OptRow, OptCol} -> {Opt, OptRow, OptCol}
        end
    end.

check_up_left(Board, Row, Col) ->
  case elem(Board, Row - 1, Col - 1) of
    c -> {Row - 1, Col - 1};
    _ -> nope
  end.
check_up(Board, Row, Col) ->
  case elem(Board, Row - 1, Col) of
    c -> {Row - 1, Col};
    _ -> nope
  end.
check_up_right(Board, Row, Col) ->
  case elem(Board, Row - 1, Col + 1) of
    c -> {Row - 1, Col + 1};
    _ -> nope
  end.
check_right(Board, Row, Col) ->
  case elem(Board, Row, Col + 1) of
    c -> {Row, Col + 1};
    _ -> nope
  end.
check_down_right(Board, Row, Col) ->
  case elem(Board, Row + 1, Col + 1) of
    c -> {Row + 1, Col + 1};
    _ -> nope
  end.
check_down(Board, Row, Col) ->
  case elem(Board, Row + 1, Col) of
    c -> {Row + 1, Col};
    _ -> nope
  end.
check_down_left(Board, Row, Col) ->
  case elem(Board, Row + 1, Col - 1) of
    c -> {Row + 1, Col - 1};
    _ -> nope
  end.
check_left(Board, Row, Col) ->
  case elem(Board, Row, Col - 1) of
    c -> {Row, Col - 1};
    _ -> nope
  end.

%%%===================================================================
%%% Advanced AI functions
%%%===================================================================
%% {{Row, Col}, {Elem, Flags, Blanks}},
%% List = {{8,1}
advanced_decision_maker(List) ->
  UsefulList = remove_finished(List).

remove_finished(List) -> remove_finished(List, []).
remove_finished([], Acc) ->
  lists:sort(Acc);
remove_finished([{{Row, Col}, {Num, Flag, Blanks}} | T], Acc) ->
  case Blanks == 0 of
    true -> remove_finished(T, Acc);
    false -> remove_finished(T, [{{Row, Col}, {Num, Flag, Blanks}}|Acc])
  end.
advanced_info(List, MaxRow, MaxCol, Board) -> advanced_info(List, MaxRow, MaxCol, Board, []).
advanced_info([{{Row, Col}, {Elem, Flags, _Blanks}}|T], MaxRow, MaxCol, Board, Acc) ->
  NewNum = Elem - Flags,
  BlankCoords = find_blank_coords(Row, Col, MaxRow, MaxCol, Board),
  advanced_info(T, MaxRow, MaxCol, Board, [{{Row,Col},NewNum, BlankCoords}|Acc]).

find_blank_coords(Row, Col, MaxRow, MaxCol, Board) -> find_blank_coords(Row, Col, MaxRow, MaxCol, Board, []).
find_blank_coords(Row, Col, MaxRow, MaxCol, Board, Acc) ->
  Acc1 =
    case check_left(Row, Col, Board) of
      nope -> Acc;
      Blank1 -> [Blank1|Acc]
    end,
  Acc2 =
    case check_up_left(Row, Col, Board) of
      nope -> Acc1;
      Blank2 -> [Blank2|Acc1]
    end,
  Acc3 =


  .


%%%===================================================================
%%% Internal functions
%%%===================================================================
blocker() -> block.

elem(Board, Row, Col) ->
  Line = lists:nth(Row, Board),
  lists:nth(Col, Line).

input_num(Name) ->
  case io:read(Name) of
    {ok, Rows} when is_integer(Rows) ->
      Rows;
    _ ->
      io:format("Please type only one integer.~n"),
      input_num(Name)
  end.

clear() ->
  io:format("\e[H\e[J"),
  io:format("MINESWEEPER v1.1 ~n"),
  io:format("~n").