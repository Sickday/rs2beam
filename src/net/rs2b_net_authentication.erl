-module(rs2b_net_authentication).
-include("rs2b_net.hrl").
-export([decode/1]).

decode(<<S1:32, S2:32, S3:32, S4:32, UID:32, Credentials/binary>>) ->
	maybe
		{<<Username/binary>>, <<R0/binary>>} ?= rs2b_stream_decoder:decode_string(Credentials),
		{<<Secret/binary>>, _} ?= rs2b_stream_decoder:decode_string(R0),
		{ok, #rs2b_net_auth{
			seed = [S1, S2, S3, S4],
			uid = UID,
			username = normalize(Username),
			secret = normalize(Secret)
		}}
	end;
decode(<<>>) ->
	{error, eof};
decode(_) ->
	{error, insufficient_data}.

normalize(String) ->
	string:lowercase(string:trim(String)).
