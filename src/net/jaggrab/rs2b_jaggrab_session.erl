-module(rs2b_jaggrab_session).

-behaviour(gen_server).


start_link([Socket]) ->
	gen_server:start_link({local, ?MODULE}, ?MODULE, #{socket => Socket}).

init(State) ->
	{ok, State}.


handle_info({tcp, _Socket, <<10:8/integer-unsigned-big>>}, State) ->
	{noreply, State};

handle_info({tcp, Socket, Request}, State) ->
	RequestString = string:trim(Request),
	Response = decode_request(RequestString),
	ResponseSize = byte_size(maps:get(Response, file_data)),

	case gen_tcp:send(Socket, maps:get(Response, file_data)) of
		ok -> {noreply, State},
		{error, Reason} -> {stop, Reason, State}
	end;

handle_info({tcp_closed, _Socket}, State) ->
	{stop, normal, State}.
