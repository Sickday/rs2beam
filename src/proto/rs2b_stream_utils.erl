-module(rs2b_stream_utils).

-compile([reverse/1, slice_frame/2, pad_to_bin/1]).

reverse(Stream) ->
	StreamSize = byte_size(Stream),
	ReversedLittle = binary:decode_unsigned(Stream, little),
	EncodedReversedBig = binary:encode_unsigned(ReversedLittle, big),
	Padding = StreamSize - byte_size(EncodedReversedBig),
	case Padding > 0 of
		true ->
			<<0:Padding/unit:8, EncodedReversedBig/binary>>;
		false ->
			EncodedReversedBig
	end.

slice_frame(<<OpCode:8/integer-unsigned-big, Rest/binary>>, []) ->
	<<>>.

pad_to_bin(BitString) when is_bitstring(BitString) and not is_binary(BitString) ->
	BitSize = bit_size(BitString),
	Padding = 8 - BitSize rem 8,
	case Padding =:= 8 of
		true ->
			BitString;
		false ->
			<<BitString/bitstring, 0:Padding/unit:8>>
	end.
