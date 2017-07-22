Redix.command! elem(ExistExtras.Redis.redis_connection, 1), ~w(FLUSHDB)

ExUnit.start()
