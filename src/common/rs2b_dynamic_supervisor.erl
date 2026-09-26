-module(rs2b_dynamic_supervisor).
-behaviour(supervisor).
-export([start_link/2, init/1]).

start_link(Name, ChildTemplate) ->
	supervisor:start_link({local, Name}, ?MODULE, ChildTemplate).

init(ChildTemplate) ->
	{ok, {#{strategy => simple_one_for_one}, [ChildTemplate]}}.
