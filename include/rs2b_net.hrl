-record(rs2b_net_listener_args, {
	port :: pos_integer(),
	count :: pos_integer(),
	handler :: term(),
	socket_opts :: list(),
	supervisor :: term(),
	name :: term()
}).

-record(rs2b_network_listener, {
	socket :: port(),
	acceptors :: list()
}).
