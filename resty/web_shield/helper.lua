local M = {}

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

return M
