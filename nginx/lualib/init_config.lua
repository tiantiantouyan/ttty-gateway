local Redis = require 'resty.redis'
local cjson = require 'cjson'
local config = require 'web_shield_config'

local reset_config =  os.getenv('RESET_WEB_SHIELD')

local redis = Redis.new()
local redis_host = os.getenv('REDIS_HOST') or '127.0.0.1'
local redis_port = os.getenv('REDIS_PORT') or 6379
local r, err = redis:connect(redis_host, redis_port)

local function write_array_to_redis(key, array)
  redis:multi()
  redis:del(key)
  for index, val in ipairs(array) do
    redis:lpush(key, val)
  end
  local r, err = redis:exec()

  if not r then ngx.log(ngx.ERR, err) end
  return r
end

local function save_config_to_redis(config, force)
  local ip_shield = config.shields[1].config
  local path_whitelist_shield = config.shields[2].config
  local path_shield = config.shields[3].config

  local whitelist_ip_key = 'web-shield:whitelist-ip'
  local blacklist_ip_key = 'web-shield:whitelist-ip'
  local path_whitelist_key = 'web-shield:whitelist-path'
  local path_threshold_key = 'web-shield:path-threshold'

  if redis:exists(whitelist_ip_key) == nil or force then
    write_array_to_redis(whitelist_ip_key, ip_shield.whitelist)
  end

  if redis:exists(blacklist_ip_key) == nil or force then
    write_array_to_redis(blacklist_ip_key, ip_shield.blacklist)
  end

  if redis:exists(path_whitelist_key) == nil or force then
    local arr = {}
    for index, filter in ipairs(path_whitelist_shield.threshold) do
      table.insert(arr, cjson.encode(filter.matcher))
    end
    write_array_to_redis(path_whitelist_key, arr)
  end

  if redis:exists(path_threshold_key) == nil or force then
    local arr = {}
    for index, filter in ipairs(path_shield.threshold) do
      table.insert(arr, cjson.encode(filter))
    end
    write_array_to_redis(path_threshold_key, arr)
  end
end

if not r then
  ngx.log(ngx.ERR, err)
else
  save_config_to_redis(config, reset_config)
end

