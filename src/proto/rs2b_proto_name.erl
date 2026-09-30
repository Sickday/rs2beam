-module(rs2b_proto_name).
-define(ALPHABET, <<"_abcdefghijklmnopqrstuvwxyz0123456789">>).
-export([
	fix/1,
	format/1,
	format_protocol/1,
	is_valid/1,
	to_long/1,
	from_long/1,
	trim_trailing_zeroes/1
]).

fix(Name) ->
	fix(Name, true, <<>>).

fix(<<$_, Rest/binary>>, _, Acc) ->
	fix(Rest, true, <<Acc/binary, $_>>);
fix(<<Char, Rest/binary>>, true, Acc) when Char >= $a, Char =< $z ->
	fix(Rest, false, <<Acc/binary, (Char - $a + $A)>>);
fix(<<Char, Rest/binary>>, _, Acc) ->
	fix(Rest, false, <<Acc/binary, Char>>);
fix(<<>>, _, Acc) ->
	Acc.

format(Name) ->
	fix(binary:replace(Name, <<" ">>, <<"_">>, [global])).

format_protocol(Name) ->
	binary:replace(string:lowercase(Name), <<" ">>, <<"_">>, [global]).

is_valid(Name) ->
	Formatted = format_protocol(Name),
	Formatted =/= <<>> andalso lists:all(fun is_name_char/1, binary_to_list(Formatted)).

is_name_char(Char) ->
	(Char >= $a andalso Char =< $z) orelse (Char >= $0 andalso Char =< $9) orelse Char =:= $_.

to_long(Name) ->
	to_long(Name, 0).

to_long(<<Char, Rest/binary>>, Acc) ->
	to_long(Rest, Acc * 37 + char_value(Char));
to_long(<<>>, Acc) ->
	trim_trailing_zeroes(Acc).

char_value(Char) when Char >= $a, Char =< $z -> 1 + Char - $a;
char_value(Char) when Char >= $A, Char =< $Z -> 1 + Char - $A;
char_value(Char) when Char >= $0, Char =< $9 -> 27 + Char - $0;
char_value(_) -> 0.

from_long(Long) ->
	from_long(Long, <<>>).

from_long(0, Acc) ->
	Acc;
from_long(N, Acc) ->
	Char = binary:at(?ALPHABET, N rem 37),
	from_long(N div 37, <<Char, Acc/binary>>).

trim_trailing_zeroes(Long) when Long =/= 0, Long rem 37 =:= 0 ->
	trim_trailing_zeroes(Long div 37);
trim_trailing_zeroes(Long) ->
	Long.
