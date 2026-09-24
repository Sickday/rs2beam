-module(rs2b_frame_decoder).

% Decode the payload of a data packet using the state passed to the function.
-callback decode_payload(Stream :: binary(), State :: any()) -> {ok, NewState :: term()} | {error, Reason :: term()}.
