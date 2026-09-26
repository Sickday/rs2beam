-module(rs2b_jaggrab_session).
-behaviour(gen_server).
-include("rs2b_jaggrab.hrl").
-export([start_link/1, init/1, handle_call/3, handle_cast/2, handle_info/2, handle_socket/1]).


start_link(Socket) ->
	gen_server:start_link(?MODULE, #{socket => Socket}, []).

init(State) ->
	{ok, State}.

handle_call(_Msg, _From, State) ->
	{reply, ok, State}.

handle_cast(_Msg, State) ->
	{noreply, State}.

handle_info({tcp, _Socket, <<10:8/integer-unsigned-big>>}, State) ->
	{noreply, State};
handle_info({tcp, Socket, Request}, State) ->
	RequestString = string:trim(Request),
	Response = decode_request(RequestString),
	ResponseSize = byte_size(Response#jaggrab_response.file_data),

	case gen_tcp:send(Socket, Response#jaggrab_response.file_data) of
		ok -> {noreply, State};
		{error, Reason} -> {stop, Reason, State}
	end;
handle_info({tcp_closed, _Socket}, State) ->
	{stop, normal, State}.

handle_socket(Socket) ->
	maybe
		{ok, HandlerPid} ?= supervisor:start_child(rs2b_jaggrab_session_supervisor, [Socket]),
		ok ?= gen_tcp:controlling_process(Socket, HandlerPid),
		ok
	else
		{error, Reason} ->
			gen_tcp:close(Socket),
			{error, Reason}
	end.

decode_request(<<"JAGGRAB /", Path/binary>>) ->
	RequestPath = string:trim(Path, trailing),
	rs2b_jaggrab_request:new(RequestPath);
decode_request(Request) ->
	{ok, Request}.
