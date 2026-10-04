-define(ARCHIVE_COUT, 9).
-define(HEADER_SIZE, 8).
-define(CHUNK_SIZE, 512).
-define(BLOCK_SIZE, (?HEADER_SIZE + ?CHUNK_SIZE)).
-define(INDEX_SIZE, 6).

-record(rs2b_cache_fs, {
	indices :: [file:io_device()],
	data :: file:io_device(),
	crc_table :: binary() | undefined,
	crcs :: [integer()] | undefined,
	read_only :: boolean()
}).

-record(rs2b_cache_index_entry, {
	size :: non_neg_integer(),
	block ::non_neg_integer()
}).

-record(rs2b_cache_archive_entry, {
	id :: integer(),
	buffer :: binary()
}).

-record(rs2b_cache_file_descriptor, {
	store ::non_neg_integer(),
	id :: non_neg_integer()
}).
