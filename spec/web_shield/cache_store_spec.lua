describe('cache store', function()
  local Helper = require 'resty.web_shield.helper'
  local Store = require 'resty.web_shield.cache_store'
  local store = Store.new()
  local redis = Helper.new_redis()

  before_each(function()
    clear_redis()
  end)

  describe("new", function()
    it('should use 127.0.0.1:6379 if not args', function()
      assert.is_equal(store.redis_config.host, nil)
      assert.is_equal(store.redis_config.port, nil)
    end)

    it('should save conn_config', function()
      config = {host = '1.2.3.4', pool_size = 2, pool_timeout = 100}
      s = Store.new(config)
      assert.is_same(s.conn_config, {pool_size = 2, pool_timeout = 100})
    end)
  end)

  describe("incr_counter", function()
    it('should return current value', function()
      assert.is_equal(store:incr_counter('a', 3), 1)
      assert.is_equal(store:incr_counter('a', 3), 2)
      assert.is_equal(store:incr_counter('b', 3), 1)
    end)

    it('should expire value', function()
      local htime = Helper.time
      Helper.time = function() return 100 end
      assert.is_equal(store:incr_counter('a', 1), 1)
      local ttl = redis:ttl('a-100')
      assert.is_equal(ttl >= 1, true)
      assert.is_equal(ttl <= 2, true)
      ngx.sleep(1)
      assert.is_equal(store:incr_counter('a', 1), 1)
      Helper.time = htime
    end)
  end)
end)
