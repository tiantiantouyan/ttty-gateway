--
-- PathShield
--
-- 2017 xiejiangzhi
--

local M ={}
M.__index = M

local Helper = require 'resty.web_shield.helper'
local Store = require 'resty.web_shield.cache_store'
local Logger = require 'resty.web_shield.logger'

-- config
--  threshold = {
--    {
--      matcher = {
--        method = ['*'], // request methods, * GET POST, PUT DELETE
--        path = "/api/v1/*"
--      },
--      period = 20, // seconds
--      limit = 15 // max requests
--    },
--    {
--      matcher = {method = ["POST", "PUT", "DELETE"], path = "*"},
--      period = 20,
--      limit = 5
--    }
--  }
function M.new(web_shield, config)
  return setmetatable({
    web_shield = web_shield,
    threshold = config.threshold
  }, M)
end

function M:filter(ip, uid, method, path)
  local store = Store.new(self.web_shield.config.redis_host, self.web_shield.config.redis_port)

  for index, filter in pairs(self.threshold) do
    local counter_key, counter_str = M.generate_counter_key(filter, ip, uid, method, path)

    if M.req_match(filter.matcher, method, path) then
      total_reqs = store:incr_counter(counter_key, filter.period)
      Logger.debug("Threshold " .. counter_str .. ' => ' .. total_reqs)
      if total_reqs > filter.limit then return Helper.BLOCK end
      if filter.break_shield then return Helper.BREAK end
    else
      Logger.debug("Skip " .. counter_str)
    end
  end

  return Helper.PASS
end


--
---- Helper
--

function M.req_match(matcher, method, path)
  return M.req_method_match(matcher.method, method) and M.req_path_match(matcher.path, path)
end

-- matcher: array, example: ['*'], ['POST', 'DELETE'], ['GET']
function M.req_method_match(matcher, method)
  local result

  for index, req_method in ipairs(matcher) do
    if req_method == '*' then
      result = true
      break
    elseif req_method == method then
      result = true
    end
  end

  if result == nil then return false end
  return result
end

-- matcher: string, example: '/api/v1/*', '/api/v1/users'
function M.req_path_match(matcher, path)
  local pattern = '^' .. string.gsub(matcher, '*', '.*') .. '$'
  return string.find(path, pattern) ~= nil
end

function M.generate_counter_key(filter, ip, uid, method, path)
  local str = table.concat({
    ip, uid, table.concat(filter.matcher.method, '-'), filter.matcher.path, filter.period
  }, '-')

  return Helper.md5(str), str
end

return M

