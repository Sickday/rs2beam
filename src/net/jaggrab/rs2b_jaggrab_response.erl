-module(rs2b_jaggrab_response).
-include("rs2b_jaggrab.hrl").
-export([to_jaggrab_response/1]).

to_jaggrab_response(Data) ->
	#jaggrab_response{file_data = Data}.
