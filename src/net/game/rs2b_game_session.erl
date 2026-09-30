-module(rs2b_game_session).
-behaviour(gen_server).
-include("rs2b_net.hrl").
-export([handle_socket/1, start_link/1]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2]).

-define(SUPERVISOR, rs2b_game_session_supervisor).
-define(LOGIN_TIMEOUT, 30000).

handle_socket(Socket) ->
	maybe
		{ok, Pid} ?= supervisor:start_child(?SUPERVISOR, [Socket]),
		ok ?= gen_tcp:controlling_process(Socket, Pid),
		{ok, Pid}
	else
		{error, Reason} ->
			gen_tcp:close(Socket),
			{error, Reason}
	end.


start_link(Socket) ->
	gen_server:start_link(?MODULE, Socket, []).

init(Socket) ->
	erlang:send_after(?LOGIN_TIMEOUT, self(), login_timeout),
	<<ServerSeed:64>> = crypto:strong_rand_bytes(8),
	{ok, #rs2b_game_session{
		socket = Socket, 
		server_seed = ServerSeed
	}}.

handle_call(_Request, _From, State) ->
	{reply, ok, State}.

handle_cast(_Msg, State) ->
	{noreply, State}.

handle_info({tcp, _Socket, Data}, #rs2b_game_session{buffer = Buffer} = State) ->
	handle_data(<<Buffer/binary, Data/binary>>, State);
handle_info({tcp_closed, _Socket}, State) ->
	{stop, normal, State};
handle_info({tcp_error, _Socket, Reason}, State) ->
	{stop, {shutdown, Reason}, State};
handle_info(login_timeout, State) ->
	{stop, normal, State};
handle_info(_Msg, State) ->
	{noreply, State}.

handle_data(<<14, _NameHash, Rest/binary>>, #rs2b_game_session{stage = connect} = State) ->
	Ack = <<0:64, 0, (State#rs2b_game_session.server_seed):64>>,
	case gen_tcp:send(State#rs2b_game_session.socket, Ack) of
		ok -> handle_data(Rest, State#rs2b_game_session{stage = login});
		{error, Reason} -> {stop, {shutdown, Reason}, State}
	end;
handle_data(<<15, _/binary>>, #rs2b_game_session{stage = connect} = State) ->
	%% TODO: OnDemand
	{stop, normal, State};
handle_data(<<Type, Size, Block:Size/binary, _/binary>>, #rs2b_game_session{stage = login} = State)
	when Type =:= 16; Type =:= 18 ->
		login(Block, State);
handle_data(<<Type, _/binary>>, #rs2b_game_session{stage = login} = State)
	when Type =:= 16; Type =:= 18 ->
		refuse(malformed_login, State);
handle_data(Partial, State) ->
	{noreply, State#rs2b_game_session{buffer = Partial}}.

login(Block, #rs2b_game_session{socket = Socket} = State) ->
	maybe
		{ok, Handshake, LoginBlock} ?= rs2b_net_handshake:decode(Block),
		{ok, AuthData} ?= decode_login_block(LoginBlock, application:get_env(rs2beam, rsa_key)),
		{ok, Auth} ?= rs2b_net_authentication:decode(AuthData),
		ok ?= check_seed(Auth, State),
		{ok, PlayerPid} = enter_world(Handshake, Auth),
		ok ?= handoff(Socket, PlayerPid),
		{stop, normal, State}
	else
		{error, Reason} -> refuse(Reason, State)
	end.

decode_login_block(<<10, AuthData/binary>>, undefined) ->
	{ok, AuthData};
decode_login_block(<<Length, Cipher:Length/binary, _/binary>>, {ok, {Exponent, Modulus}}) ->
	case crypto:mod_pow(Cipher, Exponent, Modulus) of
		<<10, AuthData/binary>> -> {ok, AuthData};
		_ -> {error, malformed_login}
	end;
decode_login_block(_, _) ->
	{error, malformed_login}.

check_seed(#rs2b_net_auth{seed = [_, _, High, Low]}, #rs2b_game_session{server_seed = Seed}) ->
	case (High bsl 32) bor Low of
		Seed -> ok;
		_ -> {error, bad_seed}
	end.

enter_world(_Handshake, _Auth) ->
	{error, login_offline}.

handoff(Socket, Pid) ->
	case gen_tcp:controlling_process(Socket, Pid) of
		ok -> ok;
		{error, _} -> {error, failed_to_create_context}
	end.

refuse(Reason, #rs2b_game_session{socket = Socket} = State) ->
	Response = rs2b_authentication_response_encoder:encode_packet({response(Reason), 0}),
	_ = gen_tcp:send(Socket, Response),
	{stop, normal, State}.

response(Reason) when Reason =:= bad_magic; Reason =:= insufficient_data; Reason =:= eof ->
	malformed_login;
response(Reason) ->
	Reason.

peer(Socket) ->
	case inet:peername(Socket) of
		{ok, {IP, Port}} -> inet:ntoa(IP) ++ ":" ++ integer_to_list(Port);
		{error, _} -> "unknown"
	end.