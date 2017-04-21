local M = {}

local cjson = require 'cjson'
local Helper = require('resty.web_shield.helper')

function M.ok()
  ngx.status = ngx.HTTP_OK
  ngx.say("OK")
  M.say_req_info()
end

function M.say_req_info()
  ngx.say("\n")

  ngx.say("WebShieldStatus: " .. cjson.encode(M.status()))
  ngx.say("WebShieldIP: " .. ngx.ctx.web_shield_ip)
  ngx.say("WebShieldMysqlLastRead: " .. (ngx.ctx.web_shield_mysql_last_read or 'nil'))
  ngx.say("\n")

  ngx.say("RemoteIP: " .. ngx.var.remote_addr)
  ngx.say("RealRemoteIP: " .. ngx.var.realip_remote_addr)
  ngx.say("Forwarded-For: " .. (ngx.var.forwarded_for or ''))
  -- ngx.say("ForwardedFor: " .. ngx.var.proxy_add_x_forwarded_for)
  ngx.say("Host: " .. ngx.var.host)
  ngx.say("Port: " .. ngx.var.server_port)
  ngx.say("Method: " .. ngx.var.request_method)
  ngx.say("Path: " .. ngx.var.uri)
  ngx.say("Header: ")
  for k, v in pairs(ngx.req.get_headers()) do
    ngx.say("  " .. k ..": " .. v)
  end
end

function M.parse_jwt(data)
  if not data then return nil end
  local auth_iter = data:gmatch("[^.]+")
  local _auth_header, auth_info, _auth_sign = auth_iter(), auth_iter(), auth_iter()
  if not auth_info then return nil end

  local ok, r = pcall(function()
    return cjson.decode(ngx.decode_base64(auth_info))
  end)

  if ok then
    return r
  else
    ngx.log(ngx.ERR, "[WebShield] jwt parse failed: " .. r)
    return nil
  end
end

-- require ngx.ctx.web_shield
-- optinos ngx.ctx.web_shield_config_store
function M.status()
  local redis_config = ngx.ctx.web_shield.config.redis
  local mysql_config

  if ngx.ctx.web_shield_config_store then
    mysql_config = ngx.ctx.web_shield_config_store.mysql_config
  end

  return {
    redis_status = M.redis_status(redis_config.host, redis_config.port),
    mysql_status = M.mysql_status(mysql_config)
  }
end

function M.redis_status(host, port)
  local st = ngx.now()
  local r, err = Helper.new_redis_with(host, port, function(redis)
    return redis:get('test-key')
  end)
  local et = ngx.now()

  if not r then
    return err
  else
    return (et - st) * 1000
  end
end

function M.mysql_status(config)
  if not config then return nil end

  local st = ngx.now()
  local r, err, ec, ss = Helper.new_mysql_with(config, function(mysql)
    return mysql:query('select 1')
  end)
  local et = ngx.now()

  if not r then
    return err .. ec .. ss
  else
    return (et - st) * 1000
  end
end


return M

