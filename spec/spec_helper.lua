_G.WebShield = require('resty.web_shield')
_G.Helper = require('resty.web_shield.helper')
_G.Logger = require('resty.web_shield.logger')
_G.cjson = require('cjson')

Logger.output_level = Logger.levels.info
Logger.set_log_dev('stdout')


local Store = require('resty.web_shield.cache_store')

function _G.clear_redis()
  Helper.new_redis_with(nil, nil, function(conn) conn:flushdb() end)
end

function _G.new_mysql_with(callback)
  return Helper.new_mysql_with({database = 'web_shield_test'}, callback)
end
function _G.clear_mysql()
  new_mysql_with(function(conn) conn:query('DROP TABLE IF EXISTS kvs') end)
end

function _G.init_mysql()
  local res, err, errcode, sqlstate = new_mysql_with(function(conn)
    return conn:query(
      "CREATE TABLE IF NOT EXISTS `kvs` (" ..
        "`id` int(11) NOT NULL AUTO_INCREMENT," ..
        "`key` varchar(255) DEFAULT NULL," ..
        "`val` text," ..
        "`created_at` datetime NOT NULL," ..
        "`updated_at` datetime NOT NULL," ..
        "PRIMARY KEY (`id`)," ..
        "UNIQUE KEY `index_kvs_on_key` (`key`)" ..
      ") ENGINE=InnoDB DEFAULT CHARSET=utf8"
    )
  end)

  if not res then
    error("Bad result: " .. err .. ": " .. errcode .. ": " .. sqlstate)
  end

  return true
end

function _G.write_mysql_kv(config_name, data)
  local key = ngx.quote_sql_str('web_shield/' .. config_name)
  local val = ngx.quote_sql_str(cjson.encode(data))
  local time = ngx.quote_sql_str(ngx.localtime())
  local sql = 'INSERT INTO `kvs` (`key`, `val`, `created_at`, `updated_at`) ' ..
    'VALUES(' .. table.concat({key, val, time, time}, ',') .. ') ' ..
    'ON DUPLICATE KEY UPDATE `val`=' .. val .. ', updated_at=' .. time

  local res, err, errcode, sqlstate = new_mysql_with(function(conn) return conn:query(sql) end)

  if res then
    return true
  else
    return nil, err
  end
end


