local M = {}
M.__index = M

local IPShield = require 'resty.web_shield.ip_shield'
local UserShield = require 'resty.web_shield.user_shield'
local Helper = require 'resty.web_shield.helper'

function M.new(config)
  return setmetatable({
    config = config
  }, M)
end

function M:check(ip, uid, req_method, uri)
  local str = table.concat({ip, uid, req_method, uri}, ' ')

  if self:check_request(ip, uid, req_method, uri) == Helper.BLOCK then
    ngx.log(ngx.INFO, "[WebShield] check " .. str .. " => BLOCK")
    return false
  else
    ngx.log(ngx.INFO, "[WebShield] check " .. str .. " => PASS")
    return true
  end
end

function M:check_request(ip, uid, method, path)
  local r1 = IPShield.new(self.config.ip_shield):filter(ip, uid, method, path)
  if r1 == Helper.BREAK then return result end

  return r1
end

return M

