-module(rs2b_net_dispatcher).
-export([initialize_counters/0, gather_counters/0, loop/3, start/1, finalize/1, send_data/2, count/1, flush/2]).

-define(TERM_KEY, dispatch_counter).

initialize_counters() ->
	Reference = counters:new(2, [write_concurrency]),
	persistent_term:put(?TERM_KEY, Reference).

gather_counters() ->
		case persistent_term:get(?TERM_KEY, {error, no_ref}) of
			{error, no_ref} ->
				{0, 0};
			Reference ->
				{counters:get(Reference, 1), counters:get(Reference, 2)}
		end.

start(Socket) ->
	Parent = self(),
	DispatcherLoop = fun() ->
		ParentRef = erlang:monitor(process, Parent),
		loop(Socket, Parent, ParentRef)
	end,
	DispatcherPid = spawn(DispatcherLoop),
	erlang:monitor(process, DispatcherPid),
	{ok, DispatcherPid}.

stop(undefined, _Timeout) -> ok;
stop(Socket, _Timeout) when is_port(Socket) -> ok;
stop(DispatcherPid, Timeout) when is_pid(DispatcherPid) ->
	Reference = erlang:monitor(process, DispatcherPid),
	erlang:send(DispatcherPid, {stop, self()}),

	receive
		{dispatcher_stopped, DispatcherPid} -> erlang:demonitor(Reference, [flush]);
		{'DOWN', Reference, process, DispatcherPid, _Reason} -> ok
	after
		Timeout -> erlang:demonitor(Reference, [flush])
	end,

	ok.

send_data(undefined, _Data) -> ok;
send_data(DispatcherPid, Data) when is_pid(DispatcherPid) ->
	erlang:send(DispatcherPid, {frame, Data}),
	ok;
send_data(DispatcherPid, Data) when is_port(DispatcherPid) ->
	case gen_tcp:send(DispatcherPid, Data) of
		ok -> ok;
		{error, Reason} -> {error, Reason}
	end.

finalize(Socket) ->
	flush(Socket, dispatch_mailbox([])),
	ok.

flush(_Socket, []) -> ok;
flush(Socket, Frames) ->
	count(Frames),
	gen_tcp:send(Socket, Frames).

count(Frames) ->
	case persistent_term:get(?TERM_KEY, undefined) of
		undefined ->
			ok;
		Reference ->
			FrameCount = length(Frames),
			counters:add(Reference, 1, 1),
			counters:add(Reference, 2, FrameCount)
	end.

loop(Socket, Parent, ParentRef) ->
	receive
		{frame, Data} ->
			case flush(Socket, dispatch_mailbox([Data])) of
				ok ->
					loop(Socket, Parent, ParentRef);
				{error, Reason} ->
					erlang:send(Parent, {dispatcher_closed, Reason}),
					ok
			end;
		{stop, From} ->
			finalize(Socket),
			erlang:send(From, {dispatcher_stopped, self()}),
			ok;
		{'DOWN', ParentRef, process, Parent, _Reason} ->
			finalize(Socket);
		_ ->
			?MODULE:loop(Socket, Parent, ParentRef)
	end.

dispatch_mailbox(Accumulator) ->
	receive
		{frame, Data} -> dispatch_mailbox([Data | Accumulator])
	after
		0 -> lists:reverse(Accumulator)
	end.
