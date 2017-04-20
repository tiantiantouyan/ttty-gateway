local M = {}

local Redis = require 'resty.redis'
local Mysql = require 'resty.mysql'
local Logger = require 'resty.web_shield.logger'
local cjson = require 'cjson'


-- Filter constans
M.BLOCK = 1
M.PASS = 2
M.BREAK = 3


-- TODO unify time: redis:time()
-- ngx.time: fast, os.time: slow
if ngx.time then
  M.time = ngx.time
else
  M.time = os.time
end

M.md5 = ngx.md5

function M.new_redis(host, port)
  local host = host or '127.0.0.1'
  local port = port or 6379
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

function M.new_redis_with(host, port, callback)
  local conn, err = M.new_redis(host, port)
  if not conn then return nil, err end
  local r = {callback(conn)}
  conn:set_keepalive(10 * 1000, 100)
  return unpack(r)
end

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

function M.new_mysql_with(config, callback)
  local conn, err = M.new_mysql(config)
  if not conn then return nil, err end
  local r = {callback(conn)}
  conn:set_keepalive(10 * 1000, 50)
  return unpack(r)
end


return M
