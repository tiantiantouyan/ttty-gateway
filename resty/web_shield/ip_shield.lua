--
-- IPShield
--
-- 2017 xiejiangzhi
--

local M ={}
M.__index = M

local Helper = require 'resty.web_shield.helper'
local Logger = require 'resty.web_shield.logger'
local Bit = require 'bit'

-- config table:
--  whitelist: {'127.0.0.1', '10.10.1.1/16'},
--  blacklist: {'123.123.123.1/24'}
--
function M.new(web_shield, config)
  return setmetatable({
    web_shield = web_shield,
    whitelist = config.whitelist,
    blacklist = config.blacklist
  }, M)
end

function M:filter(ip, uid, method, path)
  for index, ip_range in ipairs(self.blacklist) do
    if M.ip_match(ip_range, ip) then
      Logger.debug('Block blacklist ip ' .. ip)
      return Helper.BLOCK
    end
  end

  for index, ip_range in ipairs(self.whitelist) do
    if M.ip_match(ip_range, ip) then
      Logger.debug('Pass whitelist ip ' .. ip)
      return Helper.BREAK
    end
  end

  return Helper.PASS
end

-- ip_range: ip or ip/mask, exampel: '127.0.0.1', '192.168.1.1/16'
-- ip
M.ip_masks = {}
for i = 0, 32 do
  M.ip_masks[tostring(i)] = Bit.lshift(0xffffffff, 32 - i)
end

function M.ip_match(ip_range, ip)
  local iter = ip_range:gmatch("[^/]+")
  local m_ip = iter()
  local m_mask = iter() or '32'
  local mask = M.ip_masks[m_mask]

  return Bit.band(M.ip2int(m_ip), mask) == Bit.band(M.ip2int(ip), M.ip_masks[m_mask])
end

function M.ip2int(ip)
  local int = 0
  for ip in ip:gmatch("%w+") do
    int = Bit.lshift(int, 8)
    int = Bit.bor(int, tonumber(ip))
  end
  return int
end

return M

