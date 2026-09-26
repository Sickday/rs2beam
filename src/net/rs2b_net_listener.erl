-module(rs2b_net_listener).

-behaviour(gen_server).

-compile(export_all).

-include("rs2b_net.hrl").


start_link(Args) ->
	case maps:is_key(name, Args) of
		true -> gen_server:start_link({local, maps:get(name, Args)}, ?MODULE, Args, []);
		false -> gen_server:start_link(?MODULE, Args, [])
	end.

init(Args) ->
	maybe
		{ok, Socket} ?= open_socket(maps:get(port, Args)),
		{ok, Acceptors} ?= start_acceptors(Socket, Args),
		{ok, #rs2b_network_listener{socket = Socket, acceptors = Acceptors}}
	else
		{error, Reason} -> {stop, Reason}
	end.

handle_call(_Msg, _From, State) ->
	{reply, ok, State}.

handle_cast(_Msg, State) ->
	{noreply, State}.

handle_info(_Info, State) ->
	{noreply, State}.

open_socket(Port) ->
	case gen_tcp:listen(Port, rs2b_net:tcp_acceptor_socket_options()) of
		{ok, Socket} -> {ok, Socket};
		{error, Reason} -> {error, Reason}
	end.

start_acceptors(Socket, #{count := Count, handler := Handler, supervisor := Sup, socket_opts := SocketOpts}) ->
	start_acceptors(Sup, {Socket, Handler, SocketOpts}, Count, []).

start_acceptors(_Sup, _Arg, 0, Acceptors) ->
	{ok, Acceptors};
start_acceptors(Sup, Arg, Count, Acceptors) ->
	case supervisor:start_child(Sup, [Arg]) of
		{ok, Pid} ->
			start_acceptors(Sup, Arg, Count - 1, [Pid | Acceptors]);
		{error, Reason} ->
			lists:foreach(fun(Pid) -> supervisor:terminate_child(Sup, Pid) end, Acceptors),
			{error, Reason}
	end.
