-module(rs2b_proto_text).
-define(XLATE, <<" etaoihnsrdlumwcyfgpbvkxjqz0123456789 !?.,:;()-&*\\'@#+=", 16#A3, "$%\"[]">>).
-define(MAX_LENGTH, 80).
-define(NIBBLE_LIMIT, 13).
-define(BYTE_OFFSET, 195).
-export([
	pack/1,
	unpack/1,
	capitalize/1,
	filter/1,
	index_of/1,
	sanitize/1
]).

pack(Text) when is_list(Text) ->
	pack(list_to_binary(Text));
pack(Text) when is_binary(Text) ->
	pad(<< <<(encode_char(Char))/bitstring>> || <<Char>> <= truncate(Text) >>).

encode_char(Char) ->
	case index_of(Char) of
		undefined -> <<0:4>>;
		Index when Index < ?NIBBLE_LIMIT -> <<Index:4>>;
		Index -> <<(Index + ?BYTE_OFFSET):8>>
	end.

index_of(Char) when Char >= $A, Char =< $Z -> index_of(Char + 32);
index_of($\s) -> 0;
index_of($e) -> 1;
index_of($t) -> 2;
index_of($a) -> 3;
index_of($o) -> 4;
index_of($i) -> 5;
index_of($h) -> 6;
index_of($n) -> 7;
index_of($s) -> 8;
index_of($r) -> 9;
index_of($d) -> 10;
index_of($l) -> 11;
index_of($u) -> 12;
index_of($m) -> 13;
index_of($w) -> 14;
index_of($c) -> 15;
index_of($y) -> 16;
index_of($f) -> 17;
index_of($g) -> 18;
index_of($p) -> 19;
index_of($b) -> 20;
index_of($v) -> 21;
index_of($k) -> 22;
index_of($x) -> 23;
index_of($j) -> 24;
index_of($q) -> 25;
index_of($z) -> 26;
index_of(Char) when Char >= $0, Char =< $9 -> 27 + Char - $0;
index_of($!) -> 38;
index_of($?) -> 39;
index_of($.) -> 40;
index_of($,) -> 41;
index_of($:) -> 42;
index_of($;) -> 43;
index_of($() -> 44;
index_of($)) -> 45;
index_of($-) -> 46;
index_of($&) -> 47;
index_of($*) -> 48;
index_of($\\) -> 49;
index_of($') -> 50;
index_of($@) -> 51;
index_of($#) -> 52;
index_of($+) -> 53;
index_of($=) -> 54;
index_of(16#A3) -> 55;
index_of($$) -> 56;
index_of($%) -> 57;
index_of($") -> 58;
index_of($[) -> 59;
index_of($]) -> 60;
index_of(_) -> undefined.

lower(Char) when Char >= $A, Char =< $Z -> Char + 32;
lower(Char) -> Char.

pad(Bits) when bit_size(Bits) rem 8 =:= 0 -> Bits;
pad(Bits) -> <<Bits/bitstring, 0:4>>.

unpack(Data) ->
	unpack(Data, <<>>).

unpack(<<High:4, Low:4, Rest/bitstring>>, Acc) when High >= ?NIBBLE_LIMIT ->
	unpack(Rest, <<Acc/binary, (binary:at(?XLATE, (High bsl 4) + Low - ?BYTE_OFFSET))>>);
unpack(<<N:4, Rest/bitstring>>, Acc) when N < ?NIBBLE_LIMIT ->
	unpack(Rest, <<Acc/binary, (binary:at(?XLATE, N))>>);
unpack(_, Acc) ->
	rtrim(Acc).

rtrim(<<>>) ->
	<<>>;
rtrim(Binary) ->
	case binary:last(Binary) of
		$\s -> rtrim(binary:part(Binary, 0, byte_size(Binary) - 1));
		_ -> Binary
	end.

capitalize(Text) ->
	capitalize(Text, true, <<>>).

capitalize(<<Char, Rest/binary>>, _, Acc) when Char =:= $.; Char =:= $!; Char =:= $? ->
	capitalize(Rest, true, <<Acc/binary, Char>>);
capitalize(<<Char, Rest/binary>>, true, Acc) when Char >= $a, Char =< $z ->
	capitalize(Rest, false, <<Acc/binary, (Char - 32)>>);
capitalize(<<$\s, Rest/binary>>, Capital, Acc) ->
	capitalize(Rest, Capital, <<Acc/binary, $\s>>);
capitalize(<<Char, Rest/binary>>, _, Acc) ->
	capitalize(Rest, false, <<Acc/binary, Char>>);
capitalize(<<>>, _, Acc) ->
	Acc.

filter(Text) ->
	<< <<(lower(Char))>> || <<Char>> <= Text, index_of(Char) =/= undefined >>.

sanitize(Packed) ->
	Text = truncate(unpack(Packed)),
	{capitalize(Text), pack(Text)}.

truncate(Text) ->
	binary:part(Text, 0, min(byte_size(Text), ?MAX_LENGTH)).
