-module(rs2beam).
-behaviour(application).
-export([start/2, stop/1]).

start(_Type, _Args) ->
	rs2b_net_dispatcher:initialize_counters(),
	rs2b_supervisor:start_link().

stop(_State) ->
	ok.
