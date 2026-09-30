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

-record(rs2b_net_acceptor_args, {
	socket :: port(),
	handler :: term(),
	socket_opts :: list()
}).

-record(rs2b_net_acceptor, {
	socket :: port(),
	handler :: term(),
	socket_opts :: list(),
	served :: non_neg_integer(),
	last_accepted_at :: integer() | undefined,
	accept_ref :: integer() | undefined
}).

-record(rs2b_net_handshake, {
	version :: integer(),
	low_memory :: boolean(),
	crcs :: list()
}).

-record(rs2b_net_auth, {
	seed :: list(),
	uid :: integer(),
	username :: binary(),
	secret :: binary(),
	signature :: integer() | binary(),
	world :: term()
}).

-define(CLIENT_VERSION, 377).
