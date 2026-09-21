-module(stream_decoder).

-compile(export_all).

decode_u8be(<<Value:8/integer-unsigned-big, Rest/binary>>) ->
    {Value, Rest}.

decode_i8be(<<Value:8/integer-signed-big, Rest/binary>>) ->
    {Value, Rest}.

decode_u16be(<<Value:16/integer-unsigned-big, Rest/binary>>) ->
    {Value, Rest}.

decode_i16be(<<Value:16/integer-signed-big, Rest/binary>>) ->
    {Value, Rest}.

decode_u16le(<<Value:16/integer-unsigned-little, Rest/binary>>) ->
    {Value, Rest}.

decode_i16le(<<Value:16/integer-signed-little, Rest/binary>>) ->
    {Value, Rest}.

decode_u16le_add(<<Byte1:8/integer-unsigned-big,
                   Byte2:8/integer-unsigned-big,
                   Rest/binary>>) ->
    {Byte1 - 128 bor Byte2, Rest}.

decode_u32be(<<Value:32/integer-unsigned-big, Rest/binary>>) ->
    {Value, Rest}.

decode_i32be(<<Value:32/integer-signed-big, Rest/binary>>) ->
    {Value, Rest}.

decode_u32ime(<<Byte1:8/integer-unsigned-big,
                Byte2:8/integer-unsigned-big,
                Byte3:8/integer-unsigned-big,
                Byte4:8/integer-unsigned-big,
                Rest/binary>>) ->
    {Byte3 bor Byte4 bor Byte1 bor Byte2, Rest}.
