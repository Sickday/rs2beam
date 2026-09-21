-module(stream_encoder).

-include("core/common.hrl").

-compile(export_all).

encode_u8be(Bin, Value) ->
    <<Bin/binary, Value:8/integer-unsigned-big>>.

encode_i8be(Bin, Value) ->
    <<Bin/binary, Value:8/integer-signed-big>>.

encode_u16be(Bin, Value) ->
    <<Bin/binary, Value:16/integer-unsigned-big>>.

encode_i16be(Bin, Value) ->
    <<Bin/binary, Value:16/integer-signed-big>>.

encode_u16le(Bin, Value) ->
    <<Bin/binary, Value:16/integer-unsigned-little>>.

encode_i16le(Bin, Value) ->
    <<Bin/binary, Value:16/integer-signed-little>>.

encode_u16le_add(Bin, Value) ->
    <<Bin/binary,
      (Value + 128):8/integer-unsigned-big,
      (Value bsl 8):8/integer-unsigned-big>>.

encode_u32be(Bin, Value) ->
    <<Bin/binary, Value:32/integer-unsigned-big>>.

encode_i32be(Bin, Value) ->
    <<Bin/binary, Value:32/integer-signed-big>>.

encode_u32me(Bin, Value) ->
    <<Byte1, Byte2, Byte3, Byte4>> = <<Value:32/integer-unsigned-big>>,
    <<Bin/binary, Byte2, Byte1, Byte4, Byte3>>.

encode_i32me(Bin, Value) ->
    <<Byte1, Byte2, Byte3, Byte4>> = <<Value:32/integer-signed-big>>,
    <<Bin/binary, Byte2, Byte1, Byte4, Byte3>>.

encode_u32ime(Bin, Value) ->
    <<Byte1, Byte2, Byte3, Byte4>> = <<Value:32/integer-unsigned-big>>,
    <<Bin/binary, Byte3, Byte4, Byte1, Byte2>>.

encode_i32ime(Bin, Value) ->
    <<Byte1, Byte2, Byte3, Byte4>> = <<Value:32/integer-signed-big>>,
    <<Bin/binary, Byte3, Byte4, Byte1, Byte2>>.

encode_i32le(Bin, Value) ->
    <<Bin/binary, Value:32/integer-signed-little>>.

encode_u64be(Bin, Value) ->
    <<Bin/binary, Value:64/integer-unsigned-big>>.

encode_i64be(Bin, Value) ->
    <<Bin/binary, Value:64/integer-signed-big>>.

encode_bits(Bin, Value, Amount) when is_boolean(Value) ->
    <<Bin/bitstring, ?IF(Value, 1, 0):Amount>>;
encode_bits(Bin, Value, Amount) ->
    <<Bin/bitstring, Value:Amount>>.
