-module(rs2b_ondemand_supervisor).
-behaviour(supervisor).
-export([start_link/0, init/1]).

start_link() ->
	supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
	Child = #{
		id => rs2b_ondemand_session,
		start => {rs2b_ondemand_session, start_link, []},
		restart => temporary,
		type => worker
	},
	{ok, {#{strategy => simple_one_for_one}, [Child]}}.
