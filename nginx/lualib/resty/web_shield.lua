local M = {}
M.__index = M

local ControlShield = require 'resty.web_shield.control_shield'
local Helper = require 'resty.web_shield.helper'
local Logger = require 'resty.web_shield.logger'
local CacheStore = require 'resty.web_shield.cache_store'

-- config:
--  redis:
--    host:
--    port:
--    pool_size:
-- shield_config:
--  order: 'and' or 'or'
--  shields: Array of shield
function M.new(config, shield_config)
  return setmetatable({
    config = config,
    shield_config = shield_config,
    cache_store = CacheStore.new(config.redis)
  }, M)
end

function M:check(ip, uid, req_method, uri, header)
  local str = table.concat({ip, uid, req_method, uri}, ' ')
  Logger.debug("Check " .. str)

  local shield = self:new_shield('control_shield', self.shield_config)

  if shield:filter(ip, uid, req_method, uri, header) == Helper.BLOCK then
    Logger.err("BLOCK " .. str)
    return false
  else
    Logger.debug("PASS " .. str)
    return true
  end
end

--
---- Helper
--

M._cache_shield_classes = {}
function M:new_shield(name, ...)
  if name == 'path_shield' then name = 'threshold_shield' end
  local shield_cls = M._cache_shield_classes[name]
  if not shield_cls then
    shield_cls = require('resty.web_shield.' .. name)
    M._cache_shield_classes[name] = shield_cls
  end

  return shield_cls.new(self, ...)
end

return M

