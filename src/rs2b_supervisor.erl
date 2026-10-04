-module(rs2b_supervisor).
-behaviour(supervisor).
-export([start_link/0, init/1]).

start_link() ->
	supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
	{ok, {#{strategy => one_for_one}, [
		#{
			id => rs2b_cache_supervisor,
			type => supervisor,
			start => {rs2b_cache_supervisor, start_link, []}
		},
		#{
			id => rs2b_net_supervisor,
			type => supervisor,
			start => {rs2b_net_supervisor, start_link, [[]]}
		},
		#{
			id => rs2b_jaggrab_supervisor,
			type => supervisor,
			start => {rs2b_jaggrab_supervisor, start_link, []}

		}
	]}}.
