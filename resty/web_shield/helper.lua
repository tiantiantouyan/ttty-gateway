local M = {}

local MD5 = require 'resty.md5'
local String = require 'resty.string'

-- Filter constans
M.BLOCK = 1
M.PASS = 2
M.BREAK = 3


-- TODO unify time: redis
-- ngx.time: fast, os.time: slow
function M.time()
  if ngx.time then
    return ngx.time()
  else
    return os.time()
  end
end

function M.md5(str)
  local md5 = MD5:new()
  md5:update(str)
  return String.to_hex(md5:final())
end

return M
