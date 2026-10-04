-module(rs2b_cache_supervisor).
-behaviour(supervisor).
-export([start_link/0, init/1, get_pid/1, cache_servers/0]).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
	CacheConfig = application:get_env(rs2beam, cache, []),
	Path = proplists:get_value(path, CacheConfig, "cache"),
	Revisions = proplists:get_value(revisions, CacheConfig, [377]),
	Children = [#{
		id => Revision,
		start => {rs2b_cache_server, start_link, [#{path => Path, revision => Revision}]},
		restart => permanent,
		shutdown => 5000,
		type => worker} || Revision <- Revisions],
	{ok, {#{strategy => one_for_one}, Children}}.

cache_servers() ->
	lists:filtermap(fun({Id, Pid, worker, _}) when is_pid(Pid) ->
		{true, {Id, Pid}};
	(_) -> false
	end, supervisor:which_children(?MODULE)).

get_pid(Revision) ->
	case lists:keyfind(Revision, 1, cache_servers()) of
		{Revision, Pid} -> {ok, Pid};
		false -> {error, not_found}
	end.
