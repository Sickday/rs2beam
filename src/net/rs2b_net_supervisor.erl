-module(rs2b_net_supervisor).
-behaviour(supervisor).
-export([start_link/1, init/1]).


init(Args) ->
	{ok, {#{strategy => one_for_one}, children(Args)}}.

start_link(Args) ->
	supervisor:start_link({local, ?MODULE}, ?MODULE, Args).

children(_Args) ->
	[
		#{
			id => rs2b_game_acceptor_supervisor,
			type => supervisor,
			start => {rs2b_dynamic_supervisor, start_link, [
				rs2b_game_acceptor_supervisor,
				#{
					id => rs2b_game_acceptor,
					start => {rs2b_acceptor, start_link, []},
					restart => temporary
				}
			]}
		},
		#{
			id => rs2b_dispatcher_supervisor,
			type => supervisor,
			start => {rs2b_dynamic_supervisor, start_link, [
				rs2b_dispatcher_supervisor,
				#{
					id => rs2b_dispatcher_supervisor,
					start => {rs2b_net_dispatcher, start_link, []},
					restart => temporary
				}
			]}
		},
		#{
			id => rs2b_game_listener,
			start => {rs2b_net_listener, start_link, [
				#{
					name => rs2b_net_listener,
					port => application:get_env(rs2beam, game_port, 43594),
					count => application:get_env(rs2beam, game_acceptors, 16#10),
					handler => rs2b_game_session,
					socket_opts => rs2b_net:tcp_client_socket_options(),
					supervisor => rs2b_game_acceptor_supervisor}
			]}
		}
	].
