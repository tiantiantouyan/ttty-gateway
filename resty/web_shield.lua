local M = {}
M.__index = M

local ControlShield = require 'resty.web_shield.control_shield'
local Helper = require 'resty.web_shield.helper'
local Logger = require 'resty.web_shield.logger'

function M.check(config, ip, uid, req_method, uri)
  local str = table.concat({ip, uid, req_method, uri}, ' ')
  Logger.debug("Check " .. str)

  local result = ControlShield.new(config):filter(ip, uid, req_method, uri)
  if result == Helper.BLOCK then
    Logger.err("BLOCK " .. str)
    return false
  else
    Logger.debug("PASS " .. str)
    return true
  end
end

return M

