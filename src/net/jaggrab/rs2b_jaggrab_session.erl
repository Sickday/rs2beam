-module(rs2b_jaggrab_session).
-behaviour(gen_server).
-include("rs2b_jaggrab.hrl").
-include_lib("kernel/include/logger.hrl").
-export([start_link/1, init/1, handle_call/3, handle_cast/2, handle_info/2, handle_socket/1]).
-export([handle_request/2]).


start_link(Socket) ->
	gen_server:start_link(?MODULE, #{socket => Socket}, []).

init(State) ->
	{ok, State}.

handle_call(_Msg, _From, State) ->
	{reply, ok, State}.

handle_cast(_Msg, State) ->
	{noreply, State}.

handle_info({tcp, _Socket, <<"\n">>}, State) ->
	{noreply, State};
handle_info({tcp, Socket, Request}, State) ->
	TrimmedRequest = string:trim(Request),
	JRequest = decode_request(TrimmedRequest),
	{ok, CachePid} = rs2b_cache_supervisor:get_pid(377), % Temporary, we can decode the actual revision in the crc request.
	Response = handle_request(JRequest, CachePid),
	case gen_tcp:send(Socket, Response#jaggrab_response.file_data) of
		ok ->
			gen_tcp:close(Socket),
			{stop, normal, State};
		{error, Reason} -> {stop, Reason, State}
	end;
handle_info({tcp_closed, _Socket}, State) ->
	{stop, normal, State}.

handle_request(#jaggrab_request{file_path = FileType}, CachePid) ->
	case rs2b_jaggrab_request:fetch(FileType, CachePid) of
		{ok, Data} ->
			?LOG_DEBUG("[JAGGRAB] Serving ~s (~b bytes)", [FileType, byte_size(Data)], #{domain => [rs2beam, network]}),
			rs2b_jaggrab_response:to_jaggrab_response(Data);
		{error, Reason} ->
			?LOG_ERROR("[JAGGRAB] Failed to serve ~p: ~p", [FileType, Reason]),
			rs2b_jaggrab_response:to_jaggrab_response(<<>>)
	end.

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
	JaggrabPath = rs2b_jaggrab_request:find_path(RequestPath),
	rs2b_jaggrab_request:new(JaggrabPath).
