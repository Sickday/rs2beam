-module(rs2b_frame_encoder).

% Encode the payload of a data packet using the state passed to the function.
-callback encode_payload(State :: term()) -> binary().

% Encode the header of a data packet.
-callback encode_header(Payload :: binary()) -> binary().

% Encode a data packet.
-callback encode_packet(State :: term()) -> binary().
