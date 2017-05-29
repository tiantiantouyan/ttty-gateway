--
-- ThresholdShield
--
-- 2017 xiejiangzhi
--

local M ={}
M.__index = M

local Helper = require 'resty.web_shield.helper'
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
--    },
--    {
--      matcher = {
--        method = ["*"], path = "*",
--        header = {'User-Agent' = "*wekit*"}
--      },
--      period = 10,
--      limit = 5
--    }
--  }
function M.new(web_shield, config)
  return setmetatable({
    web_shield = web_shield,
    threshold = config.threshold
  }, M)
end

function M:filter(ip, uid, method, path, header)
  local store = self.web_shield.cache_store
  if not store then return Helper.PASS end

  for index, filter in pairs(self.threshold) do
    local counter_key, counter_str = M.generate_counter_key(filter, ip, uid)

    if M.req_match(filter.matcher, method, path, header) then
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

function M.req_match(matcher, method, path, header)
  return (
    M.req_method_match(matcher.method, method) and
      M.req_path_match(matcher.path, path) and
      M.req_header_match(matcher.header, header)
  )
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
  return Helper.match(path, string.gsub(matcher, '*', '.*'), {perfect_match = true})
end

function M.req_header_match(matcher, header)
  if (not matcher) or (type(matcher) ~= 'table') then return true end
  if (not header) or (type(header) ~= 'table') then return false end

  for k, v in pairs(matcher) do
    if not Helper.match(header[k], v) then return false end
  end

  return true
end

function M.generate_counter_key(filter, ip, uid)
  if not filter.id then filter.id = Helper.md5(cjson.encode(filter)) end
  local str = table.concat({ip, uid, filter.id}, '-')
  return Helper.md5(str), str
end

return M

