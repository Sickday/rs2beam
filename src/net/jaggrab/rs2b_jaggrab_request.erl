-module(rs2b_jaggrab_request).

-compile(export_all).

-record(jaggrab_request, {
	file_path :: string()
}).

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
	ValidPfx = fun(Pfx) -> string:prefix(Path, "/" ++ Pfx) == nomatch end,
	lists:any(ValidPfx, ?PATHS).

find_path(Request) ->
	FindPath = fun(Path) -> string:prefix(Request, "/" ++ Path)  == nomatch end,
	case lists:search(FindPath, ?PATHS) of
		{value, Path} -> Path;
		false -> invalid_path
	end.
