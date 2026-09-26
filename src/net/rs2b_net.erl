-module(rs2b_net).
-export([
	tcp_client_socket_options/0,
	tcp_ondemand_socket_options/0,
	tcp_JAGGRAB_socket_options/0,
	tcp_acceptor_socket_options/0
]).

tcp_client_socket_options() ->
	[
		{mode, binary},
		{active, true},
		{keepalive, true},
		{nodelay, true},
		{send_timeout, 5000},
		{send_timeout_close, true}
	].

tcp_ondemand_socket_options() ->
	[
		{mode, binary},
		{header, 0},
		{active, true},
		{nodelay, true}
	].

tcp_JAGGRAB_socket_options() ->
	[
		{mode, binary},
		{active, true},
		{packet, line},
		{nodelay, true}
	].


tcp_acceptor_socket_options() ->
	[
		{mode, binary},
		{active, true},
		{reuseaddr, true}
	].
