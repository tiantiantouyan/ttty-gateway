local M = {}

local String = require 'resty.string'

-- Filter constans
M.BLOCK = 1
M.PASS = 2
M.BREAK = 3


-- TODO unify time: redis:time()
-- ngx.time: fast, os.time: slow
function M.time()
  if ngx.time then
    return ngx.time()
  else
    return os.time()
  end
end

function M.md5(str)
  return ngx.md5(str)
end

return M
