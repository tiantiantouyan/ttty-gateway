--
-- ControlShield
--
-- 2017 xiejiangzhi
--

local M ={}
M.__index = M

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
function M.new(web_shield, config)
  if config.order == nil then
    Logger.err('Need config.order')
    return nil
  end
  if config.shields == nil or #config.shields == 0 then
    Logger.err('Need config.shields')
    return nil
  end

  return setmetatable({
    web_shield = web_shield, config = config
  }, M)
end

function M:filter(...)
  for index, desc in ipairs(self.config.shields) do
    local shield = self.web_shield:new_shield(desc.name, desc.config)
    local result = shield:filter(...)

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

return M

