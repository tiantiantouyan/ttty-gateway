local cjson = require 'cjson'

local WebShield = require 'resty.web_shield'
local ConfigStore = require 'resty.web_shield.config_store'

local config = require('web_shield_config')

local uri_args = ngx.req.get_uri_args(100)
local ip = ngx.var.realip_remote_addr

function jwt_user_id(jwt)
  if not jwt then return nil end
  local auth_iter = jwt:gmatch("[^.]+")
  local _auth_header, auth_info, _auth_sign = auth_iter(), auth_iter(), auth_iter()
  if not auth_info then return nil end

  local ok, r = pcall(function()
    return cjson.decode(ngx.decode_base64(auth_info)).user_id
  end)

  if ok then
    return r
  else
    ngx.log(ngx.ERR, "[WebShield] fetch user identifier failed: " .. r)
    return nil
  end
end

local uid = jwt_user_id(ngx.header['Authorization']) or 'nil'

local web_shield = WebShield.new(
  config.web_shield,
  ConfigStore.new(config.config_store):fetch() or config.shield
)

if not web_shield:check(ip, uid, ngx.var.request_method, ngx.var.uri) then
  ngx.exit(ngx.HTTP_TOO_MANY_REQUESTS)
end

