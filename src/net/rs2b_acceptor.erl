-module(rs2b_acceptor).
-behaviour(gen_server).
-include("rs2b_net.hrl").
-export([
	start_link/1,
	init/1,
	handle_info/2,
	handle_call/3,
	handle_cast/2,
	handle_continue/2
]).

start_link(Args) ->
	gen_server:start_link(?MODULE, Args, []).

init({Socket, Handler, SocketOpts}) ->
	{ok, #rs2b_net_acceptor{
		socket = Socket,
		handler = Handler,
		socket_opts = SocketOpts,
		served  = 0,
		last_accepted_at = undefined,
		accept_ref = undefined
	}, {continue, accept}}.

handle_call(_Msg, _From, State) ->
	{reply, ok, State}.

handle_cast(_Msg, State) ->
	{noreply, State}.

handle_continue(accept, #rs2b_net_acceptor{socket = ListenSocket} = State) ->
	case prim_inet:async_accept(ListenSocket, -1) of
		{ok, Ref} ->
			{noreply, State#rs2b_net_acceptor{
				accept_ref = Ref
			}};
		{error, Reason} ->
			{stop, Reason, State}
	end.

handle_info({inet_async, _Socket, Ref, {ok, ClientSocket}}, #rs2b_net_acceptor{socket = ListenSocket, accept_ref = Ref, handler = SocketHandler, socket_opts = SocketOpts} = State) ->
	case inet_db:lookup_socket(ListenSocket) of
		{ok, Mod} ->
			true = inet_db:register_socket(ClientSocket, Mod),
			inet:setopts(ClientSocket, SocketOpts),
			{ok, {IP, _Port}} = inet:peername(ClientSocket),
			case rs2b_ip_throttler:check_and_register(IP) of
				ok ->
					SocketHandler:handle_socket(ClientSocket),

					case prim_inet:async_accept(ListenSocket, -1) of
						{ok, NewRef} ->
							{noreply, State#rs2b_net_acceptor{
								served = State#rs2b_net_acceptor.served + 1,
								last_accepted_at = erlang:monotonic_time(millisecond),
								accept_ref = NewRef
							}};
						{error, Reason} ->
							{stop, Reason, State}
					end;
				{deny, Response} ->
					gen_tcp:send(ClientSocket, <<Response>>),
					gen_tcp:close(ClientSocket),

					case prim_inet:async_accept(ListenSocket, -1) of
						{ok, NewRef} ->
							{noreply, State#rs2b_net_acceptor{accept_ref = NewRef}};
						{error, Reason} ->
							{stop, Reason, State}
					end
			end;

		{error, closed} ->
			{stop, normal, State};
		{error, einval} ->
			{stop, normal, State};
		{error, Reason} ->
			{stop, Reason, State}
	end;

handle_info({inet_async, _Socket, Ref, {error, Reason}}, #rs2b_net_acceptor{accept_ref = Ref} = State) when Reason =:= closed; Reason =:= einval ->
	{stop, normal, State};

handle_info({inet_async, _Socket, Ref, {error, _Reason}}, #rs2b_net_acceptor{accept_ref = Ref, socket = ListenSocket} = State) ->
	case prim_inet:async_accept(ListenSocket, -1) of
		{ok, NewRef} ->
			{noreply, State#rs2b_net_acceptor{
				accept_ref = NewRef
			}};
		{error, Reason} ->
			{stop, Reason, State}
	end;
handle_info({inet_async, _Socket, _StaleRef, _Result}, State) -> {noreply, State}.
