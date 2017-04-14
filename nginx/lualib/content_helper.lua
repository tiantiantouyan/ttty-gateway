local M = {}

local Redis = require 'resty.redis'
local cjson = require 'cjson'

function M.ok()
  ngx.status = ngx.HTTP_OK
  ngx.say("OK")
  M.say_req_info()
end

function M.bad()
  ngx.status = ngx.HTTP_BAD_REQUEST
  ngx.say("Bad")
  M.say_req_info()
end

function M.say_req_info()
  ngx.say("\n")
  ngx.say("WebShield: '" .. ngx.ctx.web_shield_ip .. "'  '" .. ngx.ctx.web_shield_uid .. "'")
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

return M

