-module(rs2b_sidebar_interface_encoder).

-behaviour(rs2b_frame_encoder).

-compile(export_all).

encode_payload({TabId, InterfaceId}) ->
	P0 = <<>>,
	P1 = rs2b_stream_encoder:encode_u8be(P0, 128 - TabId),
	P2 = rs2b_stream_encoder:encode_u16be_add(P1, InterfaceId),
	P2.

encode_header(Payload) ->
	OpCode = rs377:encoder_code(?MODULE),
	<<OpCode:8/integer-unsigned-big, Payload/binary>>.

encode_packet(State) ->
	P0 = encode_payload(State),
	P1 = encode_header(P0),
	P1.

encode_bundle() ->
	SidebarList = maps:to_list(rs377:sidebar_interfaces()),
	P0 = << <<(encode_packet(Sidebar))/binary>> || Sidebar <- SidebarList >>,
	P0.
