-module(rs2b_jaggrab_request).
-compile(export_all).
-include("rs2b_jaggrab.hrl").
-include("rs2b_cache.hrl").

-define(PATHS, [
	"crc",
	"title",
	"config",
	"interface",
	"media",
	"versionlist",
	"textures",
	"wordenc",
	"sounds"
]).

is_request_valid(Path) ->
	ValidPfx = fun(Pfx) -> string:prefix(Path, Pfx) =/= nomatch end,
	lists:any(ValidPfx, ?PATHS).

find_path(Request) ->
	FindPath = fun(Path) -> string:prefix(Request, Path) =/= nomatch end,
	case lists:search(FindPath, ?PATHS) of
		{value, Path} -> Path;
		false -> invalid_path
	end.

new(Requestpath) ->
	#jaggrab_request{file_path = Requestpath}.

fetch(invalid_path, _CachePid) ->
	{error, unknown_path};
fetch("crc", CachePid) ->
	rs2b_cache_server:request_crc_table(CachePid);
fetch(FileType, CachePid) ->
	Descriptor = #rs2b_cache_file_descriptor{store = 0, id = archive_id(FileType)},
	rs2b_cache_server:request_file(CachePid, Descriptor).

archive_id("title")  -> 1;
archive_id("config") -> 2;
archive_id("interface") -> 3;
archive_id("media") -> 4;
archive_id("versionlist") -> 5;
archive_id("textures") -> 6;
archive_id("wordenc") -> 7;
archive_id("sounds") -> 8.
