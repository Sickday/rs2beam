-module(rs2b_net_supervisor).

-behaviour(supervisor).

-compile(export_all).


init(_Args) ->
	{ok, {#{strategy => one_for_one}, children()}}.

start_link(_) ->
	supervisor:start_link({local, ?MODULE}, ?MODULE, state).

children() ->
	[
		{}
	].
