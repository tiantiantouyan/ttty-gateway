local M = {}

local Redis = require 'resty.redis'
local Mysql = require 'resty.mysql'
local Logger = require 'resty.web_shield.logger'
local cjson = require 'cjson'
local Lrucache = require 'resty.lrucache'


-- Filter constans
M.BLOCK = 1
M.PASS = 2
M.BREAK = 3

M.time_offset = 0
M.time_update_interval = 60
M.cache = Lrucache.new(4)
M.time_cache_key = 'last_correct_time_at'
M.cache:set(M.time_cache_key, 0)

local time_fn
if ngx.time then
  time_fn = ngx.time
else
  time_fn = os.time
end

-- current_time: return accordant time of seconds
--  function current_time() return tonumber(redis:time()[1]) end
function M.correct_time(current_time)
  local lt = time_fn()
  if lt - M.cache:get(M.time_cache_key) < M.time_update_interval then return end
  M.cache:set(M.time_cache_key, lt)

  local status, ct = pcall(current_time)
  if status then
    if type(ct) == 'number' then
      M.time_offset = ct - lt
      Logger.info('time offset: ' .. M.time_offset)
    else
      Logger.err("correct time failed: invalid value '" .. tostring(ct) .. "'")
    end
  else
    Logger.err("correct time failed: " .. ct)
  end
end

function M.time()
  return time_fn() + M.time_offset
end

M.md5 = ngx.md5

-- https://github.com/openresty/lua-resty-redis
function M.new_redis(host, port)
  host = host or '127.0.0.1'
  port = port or 6379
  local redis = Redis:new()
  redis:set_timeout(100)
  Logger.debug('Redis connect ' .. host .. ':' .. port)
  local ok, err = redis:connect(host, port)

  if ok then
    return redis
  else
    Logger.err(err)
    return nil, err
  end
end

-- https://github.com/openresty/lua-resty-redis#set_keepalive
function M.new_redis_with(host, port, callback)
  local conn, err = M.new_redis(host, port)
  if not conn then return nil, err end
  local r = {callback(conn)}
  -- put it into the connection pool of size 100
  -- with 10 seconds max idle timeout
  conn:set_keepalive(10 * 1000, 100)
  return unpack(r)
end

-- https://github.com/openresty/lua-resty-mysql
function M.new_mysql(config)
  config.host = config.host or '127.0.0.1'
  config.port = config.port or 3306
  config.user = config.user or 'root'

  local db = Mysql:new()
  db:set_timeout(500)
  Logger.debug('Mysql connect: ' .. cjson.encode(config))
  local ok, err = db:connect(config)

  if ok then
    return db
  else
    Logger.err(err)
    return nil, err
  end
end

-- https://github.com/openresty/lua-resty-redis
function M.new_mysql_with(config, callback)
  local conn, err = M.new_mysql(config)
  if not conn then return nil, err end
  local r = {callback(conn)}
  -- put it into the connection pool of size 50
  -- with 10 seconds max idle timeout
  conn:set_keepalive(10 * 1000, 50)
  return unpack(r)
end


return M

