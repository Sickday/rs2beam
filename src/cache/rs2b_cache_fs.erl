-module(rs2b_cache_fs).
-include("rs2b_cache.hrl").
-export([open_filesystem/1, get_file/2, crc_table/1, crcs/1]).

crcs(#rs2b_cache_fs{crcs = undefined} = State) ->
	case generate_crc_table(State) of
		{ok, NewState} -> {ok, NewState#rs2b_cache_fs.crcs, NewState};
		{error, Reason} -> {error, Reason}
	end;
crcs(#rs2b_cache_fs{crcs = Crcs} = State) ->
	{ok, Crcs, State}.

crc_table(#rs2b_cache_fs{read_only = false}) ->
	{error, writable_filesystem};
crc_table(#rs2b_cache_fs{crc_table = undefined} = State) ->
	case generate_crc_table(State) of
		{ok, NewState} -> {ok, NewState#rs2b_cache_fs.crc_table, NewState};
		{error, Reason} -> {error, Reason}
	end;
crc_table(#rs2b_cache_fs{crc_table = CrcTable} = State) ->
	{ok, CrcTable, State}.

generate_crc_table(State) ->
	case file_count(0, State) of
		{ok, ArchiveCount} ->
			RawCrcs = collect_crcs(ArchiveCount, State),
			Crcs = lists:reverse(RawCrcs),
			CrcTable = build_crc_table(Crcs),
			{ok, State#rs2b_cache_fs{crc_table = CrcTable, crcs = Crcs}};
		{error, Reason} ->
			{error, Reason}
	end.

file_count(Store, #rs2b_cache_fs{indices = Indices}) ->
	case lists:nth(Store + 1, Indices) of
		undefined ->
			{error, index_not_found};
		IdxFile ->
			case file:position(IdxFile, eof) of
				{ok, Size} -> {ok, Size div ?INDEX_SIZE};
				{error, _} -> {error, unable_to_read_index_size}
			end
	end.


open_filesystem(Path) ->
	MapFunc = fun(Idx) ->
		IdxPath = filename:join(Path, "main_file_cache.idx" ++ integer_to_list(Idx)),
		case filelib:is_regular(IdxPath) of
			true ->
				case file:open(IdxPath, [read, binary, raw]) of
					{ok, Handle} -> {true, Handle};
					_ -> false
				end;
			false -> false
		end
	end,
	Indices = lists:filtermap(MapFunc, lists:seq(0, 255)),
	case Indices of
		[] ->
			{error, no_index_files};
		_ ->
			DataPath = filename:join(Path, "main_file_cache.dat"),
			case filelib:is_regular(DataPath) of
				true ->
					case file:open(DataPath, [read, binary, raw]) of
						{ok, DataHandle} ->
							{ok, #rs2b_cache_fs{
								indices   = Indices,
								data      = DataHandle,
								read_only = true,
								crc_table = undefined,
								crcs      = undefined
							}};
						{error, Reason} ->
							{error, Reason}
					end;
				false ->
					{error, no_data_file}
			end
	end.

get_file(Descriptor, #rs2b_cache_fs{} = State) ->
	case get_index(Descriptor, State) of
		{ok, #rs2b_cache_index_entry{size = Size, block = Block}} when Size > 0, Block > 0 ->
			Position = Block * ?BLOCK_SIZE,
			Blocks = case Size rem ?CHUNK_SIZE of
				0 -> Size div ?CHUNK_SIZE;
				_ -> (Size div ?CHUNK_SIZE) + 1
			end,
			case read_blocks(State#rs2b_cache_fs.data, Descriptor, Position, Size, Blocks, 0, <<>>) of
				{ok, Buffer} -> {ok, Buffer, State};
				{error, Reason} -> {error, Reason, State}
			end;
		{ok, _} ->
			{error, empty_file, State};
		{error, Reason} ->
			{error, Reason, State}
	end.

get_index(#rs2b_cache_file_descriptor{store = Store, id = Id}, #rs2b_cache_fs{indices = Indices}) ->
	case lists:nth(Store + 1, Indices) of
		undefined ->
			{error, index_not_found};
		IndexFile ->
			Position = Id * ?INDEX_SIZE,
			case file:pread(IndexFile, Position, ?INDEX_SIZE) of
				{ok, Data} -> rs2b_cache_index:decode(Data);
				eof -> {error, past_end_of_index};
				{error, Reason} -> {error, Reason}
			end
	end.

read_blocks(_Data, _Descriptor, _Position, _Size, Blocks, Blocks, Buffer) ->
	{ok, Buffer};
read_blocks(Data, Descriptor, Position, Size, Blocks, I, Buffer) ->
	case file:pread(Data, Position, ?HEADER_SIZE) of
		{ok, Header} ->
			{NextFileId, CurChunk, NextBlock, NextFileStore} = parse_header(Header),
			case I =:= CurChunk of
				false ->
					{error, chunk_id_mismatch};
				true ->
					ReadSoFar = I * ?CHUNK_SIZE,
					ChunkSize = min(Size - ReadSoFar, ?CHUNK_SIZE),
					case file:pread(Data, Position + ?HEADER_SIZE, ChunkSize) of
						{ok, Chunk} ->
							NewBuffer = <<Buffer/binary, Chunk/binary>>,
							NextPosition = NextBlock * ?BLOCK_SIZE,
							case Size > ReadSoFar + ChunkSize of
								true ->
									case NextFileStore =:= Descriptor#rs2b_cache_file_descriptor.store + 1 of
										false -> {error, file_store_mismatch};
										true ->
											case NextFileId =:= Descriptor#rs2b_cache_file_descriptor.id of
												false -> {error, file_id_mismatch};
												true ->
													read_blocks(Data, Descriptor, NextPosition, Size, Blocks, I + 1, NewBuffer)
											end
									end;
								false ->
									read_blocks(Data, Descriptor, NextPosition, Size, Blocks, I + 1, NewBuffer)
							end;
						eof -> {error, unexpected_eof};
						{error, Reason} -> {error, Reason}
					end
			end;
		eof -> {error, unexpected_eof};
		{error, Reason} -> {error, Reason}
	end.

parse_header(<<B0, B1, B2, B3, B4, B5, B6, B7>>) ->
	NextFileId    = (B0 bsl 8) bor B1,
	CurChunk      = (B2 bsl 8) bor B3,
	NextBlock     = (B4 bsl 16) bor (B5 bsl 8) bor B6,
	NextFileStore = B7,
	{NextFileId, CurChunk, NextBlock, NextFileStore}.

% eqwalizer:nowarn
-spec collect_crcs(non_neg_integer(), #rs2b_cache_fs{}) -> [integer()].
collect_crcs(ArchiveCount, State) ->
	lists:foldl(fun(Idx, Acc) ->
		Descriptor = #rs2b_cache_file_descriptor{store = 0, id = Idx},
		case get_file(Descriptor, State) of

			{ok, Data, _} -> [erlang:crc32(Data) | Acc];
			{error, _, _} -> Acc
		end
	end, [0], lists:seq(1, ArchiveCount - 1)).

-spec build_crc_table([integer()]) -> binary().
build_crc_table(Crcs) ->
	Hash = lists:foldl(fun(Crc, Acc) -> (Acc bsl 1) + Crc end, 1234, Crcs),
	lists:foldl(fun(Crc, Acc) ->
		<<Acc/binary, Crc:32/integer-signed-big>>
	end, <<>>, Crcs ++ [Hash]).
