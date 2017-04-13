local M = {}
M.__index = M

local ControlShield = require 'resty.web_shield.control_shield'
local Helper = require 'resty.web_shield.helper'
local Logger = require 'resty.web_shield.logger'

function M.new(config, shield_config)
  return setmetatable({
    config = config,
    shield_config = shield_config
  }, M)
end

function M:check(ip, uid, req_method, uri)
  local str = table.concat({ip, uid, req_method, uri}, ' ')
  Logger.debug("Check " .. str)

  local shield = self:new_shield('control_shield', self.shield_config)

  if shield:filter(ip, uid, req_method, uri) == Helper.BLOCK then
    Logger.err("BLOCK " .. str)
    return false
  else
    Logger.debug("PASS " .. str)
    return true
  end
end

M._cache_shield_classes = {}
function M:new_shield(name, ...)
  local shield_cls = M._cache_shield_classes[name]
  if not shield_cls then
    shield_cls = require('resty.web_shield.' .. name)
    M._cache_shield_classes[name] = shield_cls
  end

  return shield_cls.new(self, ...)
end

return M

