-module(rs2b_focus_decoder).

-behaviour(rs2b_frame_decoder).

-compile([decode_payload/2]).

decode_payload(Stream, State) ->
	{Focus, _} = rs2b_stream_decoder:decode_u8be(Stream),
	NewState = maps:put(focused, Focus, State),
	{ok, NewState}.
