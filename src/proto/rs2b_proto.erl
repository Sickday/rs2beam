-module(rs2b_proto).

-compile(export_all).

-define(LOGIN_RESPONSES,
		#{
			retry => 1,
			success => 2,
			bad_credentials => 3,
			invalid_password => 3,
			banned_account => 4,
			conflicting_session => 5,
			invalid_version => 6,
			world_is_full => 7,
			login_offline => 8,
			too_many_connections => 9,
			bad_seed => 10,
			rejected_session => 11,
			failed_to_create_context => 11,
			non_member => 12,
			world_offline => 13,
			update_in_progress => 14,
			too_many_attempts => 16,
			bad_position => 17,
			bad_login_server => 20,
			world_transfer => 21,
			malformed_login => 22
}).

login_response_code(Reason) ->
	maps:get(Reason, ?LOGIN_RESPONSES).

decode(Stream, State) ->
	DecodedStream = decode_stream(Stream),
	decode_streams(DecodedStream, State).

decode_streams([], State) ->
	State;
decode_streams(Payloads, State) ->
	lists:foldl(fun decode_payload/2, State, Payloads).

decode_stream(<<OpCode:8/integer-unsigned-big>>) ->
	Module = rs377:decoder_module(OpCode),
	[{Module, <<>>, OpCode}];
decode_stream(Stream) ->
	decode_stream(Stream, []).

decode_stream(<<>>, Into) ->
	lists:reverse(Into);
decode_stream(<<OpCode:8/integer-unsigned-big, Rest/binary>>, Into) ->
	FrameLength = rs377:decoder_length(OpCode),
	case  decode_stream_frame(Rest, FrameLength) of
		{ok, Payload, Rem} ->
			Module = rs377:decoder_module(OpCode),

			case byte_size(Rem) > 0 of
				true -> decode_stream(Rem, [{Module, Payload, OpCode} | Into]);
				false -> lists:reverse([{Module, Payload, OpCode} | Into])
			end;
		{error, truncated} ->
			lists:reverse(Into)
	end.


decode_stream_frame(<<Length:8, Payload:Length/binary, Rem/binary>>, -1) ->
	{ok, Payload, Rem};
decode_stream_frame(Stream, Length) when Length >= 0, byte_size(Stream) >= Length ->
	<<Payload:Length/binary, Rem/binary>> = Stream,
	{ok, Payload, Rem};
decode_stream_frame(_Stream, _Length) ->
	{error, truncated}.


decode_payload({undefined, _Payload, _OpCode}, State) ->
	State;
decode_payload({Module, Payload, _OpCode}, State) ->
	case Module:decode_packet(Payload, State) of
		{ok, NewState} ->
			NewState;
		{error, _Reason} ->
			State
	end.
