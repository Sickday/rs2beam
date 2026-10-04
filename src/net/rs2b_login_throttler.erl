-module(rs2b_login_throttler).
-behaviour(gen_server).
-include("rs2b_throttle.hrl").
-include_lib("stdlib/include/ms_transform.hrl").

-export([start_link/0, register_success/1, deregister/1, register_failure/1]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2]).

-define(TABLE, rs2b_login_throttle).
-define(ARRAY_SIZE, 65535).
-define(MAX_ATTEMPTS, 5).
-define(SWEEP_INTERVAL, 60000).
-define(ENTRY_TTL, 300000).

start_link() ->
	gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
	Atomics = atomics:new(?ARRAY_SIZE, [{signed, false}]),
	persistent_term:put(?MODULE, Atomics),
	?TABLE = ets:new(?TABLE, [named_table, public, {keypos, #rs2b_login_throttle_entry.signature}]),
	schedule_sweep(),
	{ok, []}.

register_success(Signature) ->
	deregister(Signature).

register_failure(Signature) ->
	Atomics = atomics_table(),
	EntryIdx = (Signature rem ?ARRAY_SIZE) + 1,
	NewCount = atomics:add_get(Atomics, EntryIdx, 1),
	Now = erlang:monotonic_time(millisecond),
	ets:insert(?TABLE, #rs2b_login_throttle_entry{
		signature = Signature,
		attempts = NewCount,
		last_attempt = Now
	}),
	case NewCount >= ?MAX_ATTEMPTS of
		% TODO when account profiles are added, we need to lock it here.
		true -> {deny, 16};
		false -> ok
	end.

deregister(Signature) ->
	Atomics = atomics_table(),
	EntryIdx = (Signature rem ?ARRAY_SIZE) + 1,
	atomics:put(Atomics, EntryIdx, 0),
	ets:delete(?TABLE, Signature).

handle_call(_Msg, _From, State) ->
	{reply, ok, State}.

handle_cast(_Msg, State) ->
	{noreply, State}.

handle_info(sweep, State) ->
	sweep(),
	schedule_sweep(),
	{noreply, State}.

sweep() ->
	Cutoff = erlang:monotonic_time(millisecond) - ?ENTRY_TTL,
	Func = ets:fun2ms(fun(#rs2b_login_throttle_entry{last_attempt = LastAttempt, signature = Sig}) when LastAttempt < Cutoff -> Sig end),
	Stale = ets:select(?TABLE, Func),
	Atomics = atomics_table(),
	lists:foreach(fun(Signature) when is_integer(Signature) ->
		Index = (Signature rem ?ARRAY_SIZE) + 1,
		atomics:put(Atomics, Index, 0),
		ets:delete(?TABLE, Signature)
	end, Stale).

schedule_sweep() ->
	erlang:send_after(?SWEEP_INTERVAL, self(), sweep).

-spec atomics_table() -> atomics:atomics_ref().
atomics_table() ->
	% eqwalizer:ignore
	persistent_term:get(?MODULE).
