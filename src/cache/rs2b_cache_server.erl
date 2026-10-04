-module(rs2b_cache_server).
-behaviour(gen_server).
-include("rs2b_cache.hrl").

-export([start_link/1, request_file/2, request_crc_table/1, request_crcs/1]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2]).

start_link(Opts) ->
	gen_server:start_link(?MODULE, Opts, []).

init(#{path := Path, revision := Revision}) ->
	CachePath = filename:join(Path, integer_to_list(Revision)),
	case rs2b_cache_fs:open_filesystem(CachePath) of
		{ok, Fs} ->
			{ok, #{fs => Fs, revision => Revision}};
		{error, Reason} ->
			{stop, Reason}
	end.

request_file(CachePid, #rs2b_cache_file_descriptor{} = Descriptor) ->
	gen_server:call(CachePid, {request_file, Descriptor}).

request_crc_table(CachePid) ->
	gen_server:call(CachePid, request_crc_table).

request_crcs(CachePid) ->
	gen_server:call(CachePid, request_crcs).

handle_call({request_file, Descriptor}, _From, #{fs := Fs} = State) ->
	case rs2b_cache_fs:get_file(Descriptor, Fs) of
		{ok, Data, NewFs} ->
			{reply, {ok, Data}, State#{fs => NewFs}};
		{error, Reason, NewFs} ->
			{reply, {error, Reason}, State#{fs => NewFs}}
	end;
handle_call(request_crc_table, _From, #{fs := Fs} = State) ->
	case rs2b_cache_fs:crc_table(Fs) of
		{ok, CrcTable, NewFs} ->
			{reply, {ok, CrcTable}, State#{fs => NewFs}};
		{error, Reason} ->
			{reply, {error, Reason}, State}
	end;
handle_call(request_crcs, _From, #{fs := Fs} = State) ->
	case rs2b_cache_fs:crcs(Fs) of
		{ok, Crcs, NewFs} ->
			{reply, {ok, Crcs}, State#{fs => NewFs}};
		{error, Reason} ->
			{reply, {error, Reason}, State}
	end;
handle_call(_Msg, _From, State) ->
	{reply, ok, State}.

handle_cast(_Msg, State) ->
	{noreply, State}.

handle_info(_Msg, State) ->
	{noreply, State}.

terminate(_Reason, #{fs := #rs2b_cache_fs{indices = Indices, data = Data}}) ->
	lists:foreach(fun file:close/1, Indices),
	file:close(Data).
