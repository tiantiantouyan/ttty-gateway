local M = {}
M.__index = M

local ControlShield = require 'resty.web_shield.control_shield'
local Helper = require 'resty.web_shield.helper'

function M.check(config, ip, uid, req_method, uri)
  local str = table.concat({ip, uid, req_method, uri}, ' ')

  local result = ControlShield.new(config):filter(ip, uid, req_method, uri)
  if result == Helper.BLOCK then
    ngx.log(ngx.INFO, "[WebShield] check " .. str .. " => BLOCK")
    return false
  else
    ngx.log(ngx.INFO, "[WebShield] check " .. str .. " => PASS")
    return true
  end
end

return M

