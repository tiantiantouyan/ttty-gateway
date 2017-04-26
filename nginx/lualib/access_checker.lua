local WebShield = require 'resty.web_shield'
local ConfigStore = require 'resty.web_shield.config_store'
local Helper = require('helper')

local config = require('web_shield_config')

local cjson = require 'cjson'

ngx.ctx.req_header = ngx.req.get_headers()

local ip = ngx.var.remote_addr
local jwt_table = Helper.parse_jwt(ngx.ctx.req_header.authorization)
local uid = (jwt_table and jwt_table.user_id) or 'nil'

local web_shield = WebShield.new(config.web_shield, config.shield)

ngx.ctx.web_shield = web_shield
ngx.ctx.web_shield_ip = ip
ngx.ctx.web_shield_uid = uid

if config.config_store and config.config_store.enabled then
  local config_store = ConfigStore.new(config.config_store)
  config.shield = config_store:fetch() or config.shield

  ngx.ctx.web_shield_config_store = config_store
  ngx.ctx.web_shield_mysql_last_read = config_store:last_updated_at()
end

if not web_shield:check(ip, uid, ngx.var.request_method, ngx.var.uri) then
  ngx.status = ngx.HTTP_TOO_MANY_REQUESTS
  ngx.say("Too many requests")
  ngx.exit(ngx.HTTP_TOO_MANY_REQUESTS)
end

