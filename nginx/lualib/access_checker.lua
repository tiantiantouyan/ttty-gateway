local ch = require 'content_helper'

local WebShield = require 'resty.web_shield'
local ConfigStore = require 'resty.web_shield.config_store'

local uri_args = ngx.req.get_uri_args(100)
local ip = uri_args.ip or ngx.var.remote_addr
local uid = uri_args.token or ngx.header['X-User-Token'] or '0'

ngx.ctx.web_shield_ip = ip
ngx.ctx.web_shield_uid = uid

local config_store = ConfigStore.new({
  mysql = {
    host = '192.168.99.1',
    user = 'web_shield', password = 'asdfasdf',
    database = 'ttty_config_dev',
  },
  refresh_interval = 5
})

local web_shield = WebShield.new(
  {redis_host = os.getenv('REDIS_HOST'), redis_port = 6379},
  config_store:fetch() or require('web_shield_config')
)

if not web_shield:check(ip, uid, ngx.var.request_method, ngx.var.uri) then
  ch.bad()
end

