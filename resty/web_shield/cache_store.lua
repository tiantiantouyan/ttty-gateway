local M = {}
M.__index = M

local Helper = require 'resty.web_shield.helper'
local Logger = require 'resty.web_shield.logger'


function M.new(host, port)
  return setmetatable({host = host, port = port}, M)
end

function M:incr_counter(key, period)
  local time = Helper.time()
  local incr_key = key .. '-' .. math.floor(time / period)

  local result, err = Helper.new_redis_with(self.host, self.port, function(redis)
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

