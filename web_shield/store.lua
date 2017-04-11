local M = {}
M.__index = M

local Redis = require 'resty.redis'


function M.new()
  return M.init_redis()
end

function M.init_redis()
  local redis = ngx.ctx.redis
  if redis then return redis end

  redis = Redis:new()
  ok, err = redis:connect("172.17.0.2", 6379)

  if ok then
    ngx.ctx.redis = redis
    return redis
  else
    ngx.log(ngx.ERR, err)
    return nil, err
  end
end

