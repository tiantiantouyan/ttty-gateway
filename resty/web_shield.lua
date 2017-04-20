local M = {}
M.__index = M

local ControlShield = require 'resty.web_shield.control_shield'
local Helper = require 'resty.web_shield.helper'
local Logger = require 'resty.web_shield.logger'
local CacheStore = require 'resty.web_shield.cache_store'

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

function M:status()
  local store_status

  local st = ngx.now()
  local r, err = Helper.new_redis_with(
    self.config.redis.host, self.config.redis.port, function(redis)
      return redis:get('test-a-key')
    end
  )
  local et = ngx.now()
  if not r then
    store_status = err
  else
    store_status = (et - st) * 1000
  end

  return {cache_store = store_status}
end


--
---- Helper
--

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

