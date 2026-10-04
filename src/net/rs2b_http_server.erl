-module(rs2b_http_server).
-export([start_link/1]).

start_link(Port) ->
	Pid = proc_lib:spawn_link(fun() -> init(Port) end),
	{ok, Pid}.

init(Port) ->
	case gen_tcp:listen(Port, [binary, {packet, http_bin}, {active, false}, {reuseaddr, true}]) of
		{ok, Socket} ->
			accept_loop(Socket);
		{error, _Reason} ->
			ok
	end.

accept_loop(ListenSocket) ->
	case gen_tcp:accept(ListenSocket) of
		{ok, Client} ->
			spawn(fun() -> handle_connection(Client) end),
			accept_loop(ListenSocket);
		{error, closed} ->
			ok;
		{error, _Reason} ->
			accept_loop(ListenSocket)
	end.

handle_connection(Socket) ->
	case gen_tcp:recv(Socket, 0, 5000) of
		{ok, {http_request, 'GET', {abs_path, Path}, _Version}} ->
			consume_headers(Socket),
			Body = serve_path(Path),
			send_response(Socket, Body),
			gen_tcp:close(Socket);
		{ok, _Other} ->
			gen_tcp:send(Socket, "HTTP/1.1 400 Bad Request\r\nConnection: close\r\n\r\n"),
			gen_tcp:close(Socket);
		{error, _Reason} ->
			gen_tcp:close(Socket)
	end.

consume_headers(Socket) ->
	case gen_tcp:recv(Socket, 0, 5000) of
		{ok, http_eoh} -> ok;
		{ok, {http_header, _, _, _, _}} -> consume_headers(Socket);
		_ -> ok
	end.

send_response(Socket, undefined) ->
	inet:setopts(Socket, [{packet, raw}]),
	gen_tcp:send(Socket, "HTTP/1.1 404 Not Found\r\nContent-Length: 0\r\nConnection: close\r\n\r\n");
send_response(Socket, Body) ->
	inet:setopts(Socket, [{packet, raw}]),
	gen_tcp:send(Socket, [
		"HTTP/1.1 200 OK\r\n",
		"Content-Length: ", integer_to_list(byte_size(Body)), "\r\n",
		"Content-Type: application/octet-stream\r\n",
		"Connection: close\r\n",
		"\r\n",
		Body
	]).

serve_path(Path) ->
	FileType = rs2b_jaggrab_request:find_path(string:trim(Path, leading, "/")),
	maybe
		{ok, CachePid} ?= rs2b_cache_supervisor:get_pid(377),
		{ok, Data} ?= rs2b_jaggrab_request:fetch(FileType, CachePid),
		Data
	else
		{error, _} -> undefined
	end.
