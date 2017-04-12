--
-- ControlShield
--
-- 2017 xiejiangzhi
--

local M ={}
M.__index = M
M._cache_shields = {}

local Helper = require 'resty.web_shield.helper'
local Logger = require 'resty.web_shield.logger'

-- config table:
--  order: 'or', 'or': one pass or break; 'and': all pass or one break
--  shields: {
--    {name = 'ip_shield', config = config_table}
--    {name = 'path_shield', config = config_table}
--    {name = '{xx}_shield', config = config_table}
--  }
--
function M.new(config)
  if config.order == nil then
    Logger.err('[WebShield] need config.order')
    return nil
  end
  if config.shields == nil or #config.shields == 0 then
    Logger.err('[WebShield] need config.shields')
    return nil
  end

  return setmetatable({config = config}, M)
end

function M:filter(ip, uid, method, path)
  for index, desc in ipairs(self.config.shields) do
    local shield = M.fetch_shield_cls(desc.name).new(desc.config)
    local result = shield:filter(ip, uid, method, path)

    if result == Helper.BREAK then return result end
    if result == Helper.BLOCK and self.config.order == 'and' then return result end
    if result == Helper.PASS and self.config.order == 'or' then return result end
  end

  if self.config.order == 'and' then
    -- No block
    return Helper.PASS
  else -- order == 'or'
    -- No pass or break
    return Helper.BLOCK
  end
end


--
---- Helpers
--

function M.fetch_shield_cls(name)
  local shield = M._cache_shields[name]
  if not shield then
    shield = require('resty.web_shield.' .. name)
    M._cache_shields[name] = shield
  end

  return shield
end

return M

