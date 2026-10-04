-module(rs2b_cache_index).
-include("rs2b_cache.hrl").
-export([decode/1]).

decode(Binary) when byte_size(Binary) =:= ?INDEX_SIZE ->
	<<Byte0, Byte1, Byte2, Byte3, Byte4, Byte5>> = Binary,
	{ok, #rs2b_cache_index_entry{
		size = (Byte0 bsl 16) bor (Byte1 bsl 8) bor Byte2,
		block = (Byte3 bsl 16) bor (Byte4 bsl 8) bor Byte5
	}};
decode(_) ->
	{error, incorrect_buffer_length}.
