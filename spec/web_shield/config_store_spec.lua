describe('ConfigStore', function()
  local ConfigStore = require 'resty.web_shield.config_store'
  local store_config = {mysql = {database = 'ngx_test', pool_size = 312, pool_timeout = 110}}

  _G.init_mysql()
  local store = ConfigStore.new(store_config)

  local ip1 = {'1.1.1.1'}
  local ip2 = {'1.1.1.2'}
  local path1 = {
    {matcher = {method = {'GET'}, path = '/status'}, limit = 100, period = 1},
  }
  local path2 = {
    {matcher = {method = {'GET'}, path = '*'}, limit = 10, period = 1},
    {matcher = {method = {'PUT'}, path = '*'}, limit = 10, period = 2}
  }

  before_each(function()
    clear_mysql()
    init_mysql()
    ConfigStore.cache = require('resty.lrucache').new(32)

    write_mysql_kv('ip_whitelist', ip1)
    write_mysql_kv('ip_blacklist', ip2)
    write_mysql_kv('path_whitelist', path1)
    write_mysql_kv('path_threshold', path2)
  end)

  describe("fetch", function()
    it('should return config', function()
      assert.is_equal(type(store:fetch()), 'table')
    end)

    it('should return nil if not shields', function()
      store:refresh_config()
      store.cache:set('shields', {})
      assert.is_equal(store:fetch(), nil)
      assert.is_equal(store:fetch(), nil)
    end)

    it('should return nil if error', function()
      local old_refresh = ConfigStore.refresh_config
      ConfigStore.refresh_config = function() error('test error') end

      assert.is_equal(ConfigStore.new(store_config):fetch(), nil)
      store.refresh_config = old_refresh
    end)

    it('should return cache config if error and have cache config', function()
      store:fetch()
      local old_refresh = store.refresh_config
      store.refresh_config = function() error('test error') end

      assert.is_same(store:fetch(), {
        order = 'and',
        shields = {
          {name = 'ip_shield', config = {whitelist = ip1, blacklist = ip2}},
          {name = 'path_shield', config = {threshold = path1}},
          {name = 'path_shield', config = {threshold = path2}},
        }
      })
      store.refresh_config = old_refresh
    end)
  end)

  describe("refresh_config", function()
    it('should load config from db', function()
      local s = spy.on(store, 'load_db_config')
      store:refresh_config()
      assert.spy(s).was_called()

      local c = store.cache:get('shields')
      assert.is_same(c[1].config.whitelist, ip1)
      assert.is_same(c[1].config.blacklist, ip2)
      assert.is_same(c[2].config.threshold, path1)
      assert.is_same(c[3].config.threshold, path2)

      assert.is_equal((Helper.time() - store:last_updated_at()) <= 1, true)
      s:revert()
    end)

    it('should not load db config if repeat refresh', function()
      store:refresh_config()
      store.refresh_interval = 0.3

      local s = spy.on(store, 'load_db_config')
      store:refresh_config()
      store:refresh_config()
      assert.spy(s).was_not_called()
      s:revert()
    end)

    it('should load db config if cache expired', function()
      store.refresh_interval = 0.3
      local s = spy.on(store, 'load_db_config')
      store:refresh_config()
      ngx.sleep(0.3)
      store:refresh_config()
      assert.spy(s).was_called()
      s:revert()
    end)
  end)

  describe("load_db_config", function()
    it('should load config from db', function()
      local c = store:load_db_config()
      assert.is_same(c[1].config.whitelist, ip1)
      assert.is_same(c[1].config.blacklist, ip2)
      assert.is_same(c[2].config.threshold, path1)
      assert.is_same(c[3].config.threshold, path2)
    end)

    it('should return nil if not found config', function()
      clear_mysql()
      init_mysql()
      assert.is_equal(store:load_db_config(), nil)
    end)

    it('should return nil if invalid ip config', function()
      write_mysql_kv('ip_whitelist', "invlaid data")
      assert.is_equal(store:load_db_config(), nil)
    end)

    it('should return nil if invalid filter config', function()
      write_mysql_kv('path_whitelist', "invlaid data")
      assert.is_equal(store:load_db_config(), nil)
    end)

    it('should connect db with conn_config', function()
      local s = spy.on(Helper, 'new_mysql_with')
      clear_mysql()
      init_mysql()
      assert.is_equal(store:load_db_config(), nil)
      assert.spy(s).was_called_with(
        store.mysql_config,
        {pool_size = 312, pool_timeout = 110},
        match.is_function()
      )
      s:revert()
    end)
  end)
end)
