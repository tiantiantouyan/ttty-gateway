describe("WebShield", function()
  describe(".new", function()
    local CacheStore = require 'resty.web_shield.cache_store'

    it('should init cache_store', function()
      local s = spy.on(CacheStore, 'new')
      local web_shield = WebShield.new({redis = {port = 1234}}, config)
      assert.is_not_equal(web_shield.cache_store, nil)
      assert.spy(s).was_called_with({port = 1234})
      s:revert()
    end)
  end)

  describe(".check", function()
    local ControlShield = require 'resty.web_shield.control_shield'
    local config = {
      order = "and",
      shields = {
        {name = 'ip_shield', config = {whitelist = {}, blacklist = {}}}
      }
    }
    local web_shield = WebShield.new({}, config)

    it("should new ControlShield, and call filter", function()
      local control_shield = {filter = function(...) end}
      local cs_new = ControlShield.new

      local s1 = spy.on(ControlShield, 'new')
      local s2 = spy.on(control_shield, 'filter')
      s1.callback = function() return control_shield end

      web_shield:check('1.2.3.4', 'uid', 'GET', '/mypath')
      web_shield:check('1.2.3.4', 'uid', 'GET', '/mypath', {user_agent = 'a'})
      assert.spy(s1).was_called_with(web_shield, config)
      assert.spy(s1).was_called_with(web_shield, config)
      assert.spy(s2).was_called_with(control_shield, '1.2.3.4', 'uid', 'GET', '/mypath', nil)
      assert.spy(s2).was_called_with(
        control_shield, '1.2.3.4', 'uid', 'GET', '/mypath', {user_agent = 'a'}
      )
      s1:revert()
      s2:revert()
      ControlShield.new = cs_new
    end)
  end)

  describe('new_shield', function()
    local web_shield = WebShield.new({}, config)

    it('should not raise error shield', function()
      local shields = {'control_shield', 'ip_shield', 'threshold_shield', 'path_shield'}

      for i, name in ipairs(shields) do
        web_shield:new_shield(name, {})
      end
    end)
  end)
end)


