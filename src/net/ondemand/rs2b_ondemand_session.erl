-module(rs2b_ondemand_session).
-behaviour(gen_server).
-include("rs2b_cache.hrl").
-export([handle_socket/1, start_link/1]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, handle_continue/2]).

-define(SUPERVISOR, rs2b_ondemand_supervisor).
-define(ONDEMAND_BLOCK_SIZE, 500).

handle_socket(Socket) ->
	case supervisor:start_child(?SUPERVISOR, [Socket]) of
		{ok, Pid} when is_pid(Pid) ->
			case gen_tcp:controlling_process(Socket, Pid) of
				ok -> {ok, Pid};
				{error, Reason} ->
					gen_tcp:close(Socket),
					{error, Reason}
			end;
		{ok, undefined} ->
			gen_tcp:close(Socket),
			{error, failed_to_start_session};
		{error, Reason} ->
			gen_tcp:close(Socket),
			{error, Reason}
	end.

start_link(Socket) ->
	gen_server:start_link(?MODULE, Socket, []).

init(Socket) ->
	{ok, #{socket => Socket}, {continue, response}}.

handle_continue(response, #{socket := Socket} = State) ->
	inet:setopts(Socket, rs2b_net:tcp_ondemand_socket_options()),
	case gen_tcp:send(Socket, <<0:64>>) of
		ok ->
			{noreply, State};
		{error, Reason} ->
			{stop, {error, Reason}, State}
	end.

handle_call(_Msg, _From, State) ->
	{reply, ok, State}.

handle_cast(_Msg, State) ->
	{noreply, State}.

handle_info({tcp, _Socket, <<15>>}, State) ->
	{noreply, State};
handle_info({tcp, Socket, Stream}, State) ->
	decode_request(Stream, Socket),
	{noreply, State};
handle_info({tcp_closed, _Socket}, State) ->
	{stop, normal, State};
handle_info({tcp_error, _Socket, Reason}, State) ->
	{stop, {shutdown, Reason}, State};
handle_info(_Msg, State) ->
	{noreply, State}.

decode_request(<<Store:8, Id:16, _Priority:8>>, Socket) ->
	handle_request(Store, Id, Socket);
decode_request(<<Store:8, Id:16, _Priority:8, Rest/binary>>, Socket) ->
	handle_request(Store, Id, Socket),
	decode_request(Rest, Socket);
decode_request(Incomplete, _Socket) when byte_size(Incomplete) < 4 ->
	ok.

handle_request(Store, Id, Socket) ->
	case rs2b_cache_supervisor:get_pid(377) of
		{ok, CachePid} ->
			Descriptor = #rs2b_cache_file_descriptor{store = Store + 1, id = Id},
			case rs2b_cache_server:request_file(CachePid, Descriptor) of
				{ok, Data} -> send_file(Data, Store, Id, Socket);
				{error, _Reason} -> ok
			end;
		{error, not_found} ->
			ok
	end.

send_file(Data, Store, Id, Socket) ->
	TotalSize = byte_size(Data),
	Blocks = case TotalSize rem ?ONDEMAND_BLOCK_SIZE of
		0 -> TotalSize div ?ONDEMAND_BLOCK_SIZE;
		_ -> (TotalSize div ?ONDEMAND_BLOCK_SIZE) + 1
	end,
	send_blocks(Data, Store, Id, TotalSize, Blocks, 0, 0, Socket).

send_blocks(_Data, _Store, _Id, _TotalSize, Blocks, Blocks, _Sent, _Socket) ->
	ok;
send_blocks(Data, Store, Id, TotalSize, Blocks, BlockId, Sent, Socket) ->
	ChunkSize = min(TotalSize - Sent, ?ONDEMAND_BLOCK_SIZE),
	<<_:Sent/binary, Chunk:ChunkSize/binary, _/binary>> = Data,
	Response = <<
		Store:8,
		Id:16,
		TotalSize:16,
		BlockId:8,
		Chunk/binary
	>>,
	case gen_tcp:send(Socket, Response) of
		ok ->
			send_blocks(Data, Store, Id, TotalSize, Blocks, BlockId + 1, Sent + ChunkSize, Socket);
		{error, Reason} ->
			{error, Reason}
	end.
