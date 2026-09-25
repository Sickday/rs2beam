-module(rs2b_logout_encoder).

-behaviour(rs2b_frame_encoder).

-compile(export_all).

encode_payload(State) -> State.

encode_header(_Payload) ->
	OpCode = rs377:encoder_code(?MODULE),
	<<OpCode:8/integer-unsigned-big>>.

encode_packet(State) ->
	P0 = encode_payload(State),
	P1 = encode_header(P0),
	P1.
