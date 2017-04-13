_G.WebShield = require('resty.web_shield')
_G.Helper = require('resty.web_shield.helper')
_G.Logger = require('resty.web_shield.logger')

_G.Logger.output_level = Logger.levels.info
_G.Logger.set_log_dev('stdout')


local Store = require('resty.web_shield.store')

_G.clear_redis = function()
  Store.new().redis:flushdb()
end

