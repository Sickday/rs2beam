-module(rs2b_authentication_response_encoder).

-behaviour(rs2b_frame_encoder).

-compile(export_all).


encode_payload({success, Rights}) ->
	P0 = <<>>,
	LoginResponseCode = rs2b_proto:login_response_code(success),
	P1 = rs2b_stream_encoder:encode_u8be(P0, LoginResponseCode),
	P2 = rs2b_stream_encoder:encode_u8be(P1, Rights),
	P3 = rs2b_stream_encoder:encode_u8be(P2, 0),
	P3;

encode_payload({Response, _Rights}) ->
	P0 = <<>>,
	LoginResponseCode = rs2b_proto:login_response_code(Response),
	P1 = rs2b_stream_encoder:encode_u8be(P0, LoginResponseCode),
	P1.

encode_header(Payload) -> Payload.


encode_packet(State) ->
	P0 = <<>>,
	P1 = encode_payload(State),
	P2 = encode_header(P1),
	P2.
