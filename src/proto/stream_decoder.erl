-module(stream_decoder).

-compile(export_all).


decode_u8be(<<Value:8/integer-unsigned-big, Rest/binary>>) ->
    {Value, Rest};
decode_u8be(<<>>) ->
    {error, eof}.

decode_u8be_add(<<Value:8/integer-unsigned-big, Rest/binary>>) ->
    {(Value - 128) band 16#FF, Rest};
decode_u8be_add(<<>>) ->
    {error, eof}.

decode_i8be(<<Value:8/integer-signed-big, Rest/binary>>) ->
    {Value, Rest};
decode_i8be(<<>>) ->
    {error, eof}.

decode_i8be_sub(<<Value:8/integer-signed-big, Rest/binary>>) ->
    {128 - Value, Rest};
decode_i8be_sub(<<>>) ->
    {error, eof}.

decode_i8be_neg(<<Value:8/integer-signed-big, Rest/binary>>) ->
    {-Value, Rest};
decode_i8be_neg(<<>>) ->
    {error, eof}.

decode_u16be(<<Value:16/integer-unsigned-big, Rest/binary>>) ->
    {Value, Rest};
decode_u16be(<<>>) ->
    {error, eof}.

decode_u16be_add(<<Byte1:8, Byte2:8, Rest/binary>>) ->
    {Byte1 bsl 8 bor ((Byte2 - 128) band 16#FF), Rest};
decode_u16be_add(<<>>) ->
    {error, eof}.

decode_i16be(<<Value:16/integer-signed-big, Rest/binary>>) ->
    {Value, Rest};
decode_i16be(<<>>) ->
    {error, eof}.

decode_u16le(<<Value:16/integer-unsigned-little, Rest/binary>>) ->
    {Value, Rest};
decode_u16le(<<>>) ->
    {error, eof}.

decode_i16le(<<Value:16/integer-signed-little, Rest/binary>>) ->
    {Value, Rest};
decode_i16le(<<>>) ->
    {error, eof}.

decode_u16le_add(<<Byte1:8, Byte2:8, Rest/binary>>) ->
    {Byte2 bsl 8 bor ((Byte1 - 128) band 16#FF), Rest};
decode_u16le_add(<<>>) ->
    {error, eof}.

decode_u24be(<<Value:24/integer-unsigned-big, Rest/binary>>) ->
    {Value, Rest};
decode_u24be(<<>>) ->
    {error, eof}.

decode_u32be(<<Value:32/integer-unsigned-big, Rest/binary>>) ->
    {Value, Rest};
decode_u32be(<<>>) ->
    {error, eof}.

decode_i32be(<<Value:32/integer-signed-big, Rest/binary>>) ->
    {Value, Rest};
decode_i32be(<<>>) ->
    {error, eof}.

decode_u32le(<<Value:32/integer-unsigned-little, Rest/binary>>) ->
    {Value, Rest};
decode_u32le(<<>>) ->
    {error, eof}.

overflow(Integer) when Integer band 16#80000000 =/= 0 ->
    Integer - 16#100000000;
overflow(Integer) when Integer band 16#80000000 =:= 0 ->
    Integer.

decode_i32me(<<Byte1:8, Byte2:8, Byte3:8, Byte4:8, Rest/binary>>) ->
    Raw = Byte2 bsl 24 bor Byte1 bsl 16 bor Byte4 bsl 8 bor Byte3,
    {overflow(Raw), Rest};
decode_i32me(<<>>) ->
    {error, eof}.

decode_u32me(<<Byte1:8, Byte2:8, Byte3:8, Byte4:8, Rest/binary>>) ->
    {Byte2 bsl 24 bor Byte1 bsl 16 bor Byte4 bsl 8 bor Byte3, Rest};
decode_u32me(<<>>) ->
    {error, eof}.

decode_i32ime(<<Byte1:8, Byte2:8, Byte3:8, Byte4:8, Rest/binary>>) ->
    Value = Byte3 bsl 24 bor Byte4 bsl 16 bor Byte1 bsl 8 bor Byte2,
    {overflow(Value), Rest};
decode_i32ime(<<>>) ->
    {error, eof}.

decode_u32ime(<<Byte1:8, Byte2:8, Byte3:8, Byte4:8, Rest/binary>>) ->
    {Byte3 bsl 24 bor Byte4 bsl 16 bor Byte1 bsl 8 bor Byte2, Rest};
decode_u32ime(<<>>) ->
    {error, eof}.

decode_u64be(<<Value:64/integer-unsigned-big, Rest/binary>>) ->
    {Value, Rest};
decode_u64be(<<>>) ->
    {error, eof}.

decode_i64be(<<Value:64/integer-signed-big, Rest/binary>>) ->
    {Value, Rest};
decode_i64be(<<>>) ->
    {error, eof}.

decode_u64le(<<Value:64/integer-unsigned-little, Rest/binary>>) ->
    {Value, Rest};
decode_u64le(<<>>) ->
    {error, eof}.

decode_i64le(<<Value:64/integer-signed-little, Rest/binary>>) ->
    {Value, Rest};
decode_i64le(<<>>) ->
    {error, eof}.

decode_string(Stream) ->
    decode_string(Stream, "").
decode_string(<<10, Rest/binary>>, String) ->
    {String, Rest};
decode_string(<<Byte, Rest/binary>>, String) ->
    decode_string(Rest, <<String, Byte>>);
decode_string(<<>>, String) ->
    {String, <<>>}.
