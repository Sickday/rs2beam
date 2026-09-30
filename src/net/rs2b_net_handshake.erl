-module(rs2b_net_handshake).
-include("rs2b_net.hrl").
-export([decode/1]).

decode(<<255, ?CLIENT_VERSION:16, MemoryFlag:8, RawCRCs:36/binary, Rest/binary>>) ->
	CRCs = decode_crcs(RawCRCs),
	{ok, #rs2b_net_handshake{
		version = ?CLIENT_VERSION,
		low_memory = (MemoryFlag =:= 1),
		crcs = CRCs
	}, Rest};
decode(<<255, Version:16, _/binary>>) when Version =/= ?CLIENT_VERSION ->
	{error, invalid_version};
decode(<<Magic, _/binary>>) when Magic =/= 255 ->
	{error, bad_magic};
decode(<<>>) ->
	{error, eof};
decode(_) ->
	{error, insufficient_data}.


decode_crcs(<<Raw:(4 * 9)/binary, _/binary>>) ->
	[CRC || <<CRC:32/signed>> <= Raw].
