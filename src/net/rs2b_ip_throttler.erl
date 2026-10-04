-module(rs2b_ip_throttler).
-behaviour(gen_server).
-include("rs2b_throttle.hrl").
-include_lib("stdlib/include/ms_transform.hrl").

-export([start_link/0, check_and_register/1, deregister/1]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2]).

-define(TABLE, rs2b_ip_throttle).
-define(SWEEP_INTERVAL, 30000).
-define(ENTRY_TTL, 60000).
-define(MAX_CONNECTIONS, 4).
-define(RATE_INTERVAL, 1000).

start_link() ->
	gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
	?TABLE = ets:new(?TABLE, [named_table, public, {keypos, #rs2b_ip_throttle_entry.ip}]),
	schedule_sweep(),
	{ok, []}.

check_and_register(IP) ->
	Now = erlang:monotonic_time(millisecond),
	case ets:lookup(?TABLE, IP) of
		[] ->
			ets:insert_new(?TABLE, #rs2b_ip_throttle_entry{
				ip = IP,
				last_seen = Now,
				count = 1
			}),
			ok;
		[#rs2b_ip_throttle_entry{} = Entry] ->
			TimeSince = Now - Entry#rs2b_ip_throttle_entry.last_seen,
			case TimeSince < ?RATE_INTERVAL of
				true ->
					{deny, 16};
				false ->
					NewCount = ets:update_counter(?TABLE, IP,  {#rs2b_ip_throttle_entry.count, 1}),
					ets:update_element(?TABLE, IP, {#rs2b_ip_throttle_entry.last_seen, Now}),
					case NewCount > ?MAX_CONNECTIONS of
						true ->
							% Refused connections don't hold a slot.
							deregister(IP),
							{deny, 9};
						false -> ok
					end
			end
	end.

deregister(IP) ->
	try ets:update_counter(?TABLE, IP, {#rs2b_ip_throttle_entry.count, -1}) of
		Count when Count =< 0 -> ets:delete(?TABLE, IP), ok;
		_ -> ok
	catch
		% The entry was already swept.
		error:badarg -> ok
	end.

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
	Func = ets:fun2ms(fun(#rs2b_ip_throttle_entry{last_seen = LastSeen}) when LastSeen < Cutoff -> true end),
	ets:select_delete(?TABLE, Func).

schedule_sweep() ->
	erlang:send_after(?SWEEP_INTERVAL, self(), sweep).
