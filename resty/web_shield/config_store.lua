--
-- WebShield ConfigStore
--
-- Shields Config Struct:
--
-- {
--  order = 'and',
--  shields = {
--    -- ip whitelist/blacklist
--    {name = 'ip_whitelist', config = {...}},
--    -- path whitelist, set `break_shield = true`
--    {name = 'path_threshold', config = {...}},
--    -- path threshold
--    {name = 'path_threshold', config = {...}},
--  }
-- }
--
--

local M = {}
M.__index = M

local Helper = require 'resty.web_shield.helper'
local Logger = require 'resty.web_shield.logger'
local cjson = require 'cjson'
local Lrucache = require 'resty.lrucache'

M.cache = Lrucache.new(16)
M.cache:set('shields', {})

local keys = {'ip_whitelist', 'ip_blacklist', 'path_whitelist', 'path_threshold'}
local CONFIG_KEYS = {}
for index, key in ipairs(keys) do
  table.insert(CONFIG_KEYS, ngx.quote_sql_str('web_shield/' .. key))
end


-- config:
--  refresh_interval: 60
--  mysql:
--    host
--    port
--    user
--    password
--    database
--    ...
function M.new(config)
  local obj = setmetatable({
    mysql_config = config.mysql,
    refresh_interval = config.refresh_interval or 60
  }, M)

  obj:refresh_config()

  return obj
end

function M:fetch()
  local ok, err = pcall(self.refresh_config, self)
  if not ok then Logger.err(err) end
  local shields = M.cache:get('shields')

  if not (shields and #shields >= 3) then
    return nil
  else
    return {order = 'and', shields = shields}
  end
end

function M:refresh_config()
  if not M.cache:get('last_updated') then
    M.cache:set('last_updated', 1, self.refresh_interval)
    local shields, err = self:load_db_config()
    if shields and #shields > 0 then
      Logger.debug('Refreshed config success')
      M.cache:set('shields', shields)
      return true
    else
      Logger.err('Refreshed config failed: ' .. err)
      return false
    end
  else
    Logger.debug('Use cache config')
    return false
  end
end

function M:load_db_config()
  local res, err = assert(Helper.new_mysql_with(self.mysql_config, function(conn)
    return conn:query(
      'SELECT `key`, `val` FROM `kvs` WHERE `key` in (' ..
        table.concat(CONFIG_KEYS, ',') .. ')'
    )
  end))

  if not res then
    return nil, err
  elseif #res ~= #CONFIG_KEYS then
    return nil, "Query data < keys"
  end

  local shields = {
    {name = 'ip_shield', config = {}},
    {name = 'path_shield', config = {}},
    {name = 'path_shield', config = {}}
  }

  for index, row in ipairs(res) do
    local val = cjson.decode(row.val)

    if row.key == 'web_shield/ip_whitelist' then
      if M.check_ip_data(val) then
        shields[1].config.whitelist = val
      else
        return nil, "Invalid ip_whitelist"
      end
    elseif row.key == 'web_shield/ip_blacklist' then
      if M.check_ip_data(val) then
        shields[1].config.blacklist = val
      else
        return nil, "Invalid ip_whitelist"
      end
    elseif row.key == 'web_shield/path_whitelist' then
      if M.check_filter_data(val) then
        shields[2].config.threshold = val
      else
        return nil, "Invalid path_whitelist"
      end
    elseif row.key == 'web_shield/path_threshold' then
      if M.check_filter_data(val) then
        shields[3].config.threshold = val
      else
        return nil, "Invalid path_threshold"
      end
    end
  end

  return shields
end

function M.check_ip_data(data)
  if not (type(data) == 'table') then return nil, "Need a IP list" end

  for index, ip in ipairs(data) do
    if not (ip:match("^%d+.%d+.%d+.%d+$") or ip:match("^%d+.%d+.%d+.%d+/%d+$")) then
      return nil, "Invalid IP '" .. ip .. "'"
    end
  end

  return true
end

function M.check_filter_data(data)
  if not (type(data) == 'table') then return nil, "Need a filter list" end

  for index, checker in ipairs(data) do
    local matcher = checker.matcher
    if not (matcher and type(matcher.method) == 'table' and type(matcher.path) == 'string') then
      return nil, "Invalid matcher"
    end
    if not (type(checker.limit) == 'number' and checker.limit > 0) then
      return nil, "Invalid limit '" .. limit .. "'"
    end
    if not (type(checker.period) == 'number' and checker.period > 0) then
      return nil, "Invalid period '" .. period .. "'"
    end
  end

  return true
end

return M

