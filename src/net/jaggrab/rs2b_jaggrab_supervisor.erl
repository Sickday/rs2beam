-module(rs2b_jaggrab_supervisor).

-behaviour(supervisor).

-export([start_link/0, init/1]).

start_link() ->
	supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
	{ok, {#{strategy => one_for_one}, children()}}.


children() ->
	[
		#{
			id => rs2b_jaggrab_session_supervisor,
			type => supervisor,
			start => {rs2b_dynamic_supervisor, start_link, [
				rs2b_jaggrab_session_supervisor,
				#{
					id => rs2b_jaggrab_session,
					start => {rs2b_jaggrab_session, start_link, []},
					restart => temporary
				}
			]}
		},
		#{
			id => rs2b_jaggrab_acceptor_supervisor,
			type => supervisor,
			start => {rs2b_dynamic_supervisor, start_link, [
				rs2b_jaggrab_acceptor_supervisor,
				#{
					id => rs2b_jaggrab_acceptor,
					start => {rs2b_jaggrab_acceptor, start_link, []},
					restart => permanent
				}
			]}
		},
		#{
			id => rs2b_jaggrab_listener,
			start => {rs2b_net_listener, start_link, [
				#{
					name => rs2b_net_listener,
					port => application:get_env(rs2beam, jaggrab_port, 43595),
					count => application:get_env(rs2beam, jaggrab_acceptors, 16#10),
					handler => rs2b_jaggrab_session,
					socket_opts => rs2b_net:tcp_JAGGRAB_socket_options(),
					supervisor => rs2b_jaggrab_acceptor_supervisor}
			]}
		}
	].
