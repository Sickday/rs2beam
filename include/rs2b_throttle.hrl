-record(rs2b_ip_throttle_entry, {
	ip :: inet:ip_address(),
	count :: non_neg_integer(),
	last_seen :: integer()
}).

-record(rs2b_login_throttle_entry, {
	signature :: integer(),
	attempts :: non_neg_integer(),
	last_attempt :: integer()
}).
