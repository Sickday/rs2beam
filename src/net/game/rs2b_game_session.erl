-module(rs2b_game_session).
-behaviour(gen_server).

start_link([Socket]) ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, Socket).

acknowledge(SessionPid) ->
    gen_server:call(SessionPid, acknowledge).

send_data(Stream, Socket) ->
    case gen_tcp:send(Socket, Stream) of
        ok ->
            ok;
        {error, Reason} ->
            {error, Reason}
    end.

decode_handeshake(EncodedRequest, LoginBlock) ->
    ok.
