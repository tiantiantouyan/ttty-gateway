local M = {}
M.__index = M

local Redis = require 'resty.redis'
local Helper = require 'resty.web_shield.helper'
local Logger = require 'resty.web_shield.logger'


function M.new(host, port)
  local redis, err = M.init_redis(host or '127.0.0.1', port or 6379)
  if not redis then return nil, err end

  return setmetatable({redis = redis}, M)
end

function M:incr_counter(key, period)
  local redis = self.redis
  local time = Helper.time()

  redis:multi()
  redis:incr(key .. '-' .. math.floor(time / period))
  redis:expire(key, period)
  local result, err = redis:exec()

  if result then
    return result[1]
  else
    return 0
  end
end


--
---- Helper
--

function M.init_redis(host, port)
  local cache_key = table.concat({'redis', host, port}, '-')
  local redis = ngx.ctx[cache_key]
  if redis then return redis end

  redis = Redis:new()
  redis:set_timeout(100)
  Logger.debug('Redis connect ' .. host .. ':' .. port)
  ok, err = redis:connect(host, port)

  if ok then
    ngx.ctx[cache_key] = redis
    return redis
  else
    ngx.log(ngx.ERR, err)
    return nil, err
  end
end

return M

