local M = {}
M.__index = M

local Helper = require 'resty.web_shield.helper'
local Logger = require 'resty.web_shield.logger'


-- config:
--  host:
--  port:
--  pool_size:
function M.new(config)
  local redis_config = {}
  local conn_config = {}
  for k, v in pairs(config or {}) do redis_config[k] = v end
  for i, k in ipairs({'pool_size', 'pool_timeout'}) do
    conn_config[k] = redis_config[k]
    redis_config[k] = nil
  end

  return setmetatable({redis_config = redis_config, conn_config = conn_config}, M)
end

function M:incr_counter(key, period)
  local time = Helper.time()
  local incr_key = key .. '-' .. math.floor(time / period)

  local result, err = Helper.new_redis_with(self.redis_config, self.conn_config, function(redis)
    redis:multi()
    redis:incr(incr_key)
    redis:expire(incr_key, period)
    return redis:exec()
  end)

  if result then
    return result[1]
  else
    Logger.err(err)
    return 0
  end
end

return M

