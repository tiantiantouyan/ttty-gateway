describe("WebShield", function()
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

      local s1 = spy.on(ControlShield, 'new')
      local s2 = spy.on(control_shield, 'filter')
      s1.callback = function() return control_shield end

      web_shield:check('1.2.3.4', 'uid', 'GET', '/mypath')
      assert.spy(s1).was_called_with(web_shield, config)
      assert.spy(s2).was_called_with(control_shield, '1.2.3.4', 'uid', 'GET', '/mypath')
    end)
  end)
end)


