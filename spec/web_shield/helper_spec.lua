describe('helper', function()
  local Helper = require 'resty.web_shield.helper'

  describe('time', function()
    it('should return current timestamp', function()
      assert.is_equal(Helper.time(), ngx.time())
    end)
  end)

  describe('md5', function()
    it('should return md5 hex', function()
      assert.is_equal(Helper.md5('hello'), '5d41402abc4b2a76b9719d911017c592')
    end)
  end)

  describe('new_redis', function()
    local Redis = require 'resty.redis'

    it('should connect local redis if not give config', function()
      local r = Redis.new()
      local s1 = spy.on(Redis, 'new')
      local s2 = spy.on(r, 'connect')
      s1.callback = function() return r end

      assert.is_equal(Helper.new_redis(), r)
      assert.spy(s1).was_called()
      assert.spy(s2).was_called_with(match.is_table(), '127.0.0.1', 6379)
    end)

    it('should connect specify redis if give config', function()
      local r = Redis.new()
      local s1 = spy.on(Redis, 'new')
      local s2 = spy.on(r, 'connect')
      s1.callback = function() return r end

      assert.is_equal(Helper.new_redis('1.2.3.4', 1234), nil)
      assert.spy(s1).was_called()
      assert.spy(s2).was_called_with(match.is_table(), '1.2.3.4', 1234)
    end)
  end)

  describe('new_db', function()
    local Mysql = require 'resty.mysql'
    local config = {
      host = '127.0.0.1',
      port = '3306',
      user = 'root',
      password = '',
      database = 'ngx_test'
    }

    it('should connect specify db', function()
      local db = Mysql.new()
      local s1 = spy.on(Mysql, 'new')
      local s2 = spy.on(db, 'connect')
      s1.callback = function() return db end

      assert.is_equal(Helper.new_mysql(config), db)
      assert.spy(s1).was_called()
      assert.spy(s2).was_called_with(match.is_table(), config)
    end)
  end)
end)
