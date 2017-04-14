describe("PathShield", function()
  local PathShield = require 'resty.web_shield.path_shield'

  before_each(function()
    clear_redis()
  end)

  describe("filter", function()
    local config = {
      threshold = {
        {
          matcher = {method = {'GET'}, path = '/status'},
          period = 5, limit = 10, break_shield = true
        },

        {matcher = {method = {'*'}, path = '*'}, period = 5, limit = 3},
        {matcher = {method = {'*'}, path = '*'}, period = 12, limit = 5},
        {matcher = {method = {'PUT', "DELETE"}, path = '/users/*'}, period = 5, limit = 1}
      }
    }
    local web_shield = WebShield.new({}, {})
    local shield = PathShield.new(web_shield, config)

    it("should pass if no over limit", function()
      assert.is_equal(shield:filter('1.1.1.1', 'uid', 'GET', '/'), Helper.PASS)
    end)

    it('should block if over *(1) limit', function()
      assert.is_equal(shield:filter('1.1.1.1', 'uid', 'GET', '/'), Helper.PASS)
      assert.is_equal(shield:filter('1.1.1.1', 'uid', 'GET', '/'), Helper.PASS)
      assert.is_equal(shield:filter('1.1.1.1', 'uid', 'GET', '/'), Helper.PASS)
      assert.is_equal(shield:filter('1.1.1.1', 'uid', 'GET', '/'), Helper.BLOCK)
    end)

    it('should block if over *(2) limit', function()
      local s = spy.on(Helper, 'time')

      s.callback = function() return 1000 end
      assert.is_equal(shield:filter('1.1.1.1', 'uid', 'GET', '/'), Helper.PASS)
      assert.is_equal(shield:filter('1.1.1.1', 'uid', 'GET', '/'), Helper.PASS)
      assert.is_equal(shield:filter('1.1.1.1', 'uid', 'GET', '/'), Helper.PASS)

      s.callback = function() return 1005 end
      assert.is_equal(shield:filter('1.1.1.1', 'uid', 'GET', '/'), Helper.PASS)
      assert.is_equal(shield:filter('1.1.1.1', 'uid', 'GET', '/'), Helper.PASS)
      assert.is_equal(shield:filter('1.1.1.1', 'uid', 'GET', '/'), Helper.BLOCK)
    end)

    it('should block if over /users/* limit', function()
      local s = spy.on(Helper, 'time')

      s.callback = function() return 1000 end
      assert.is_equal(shield:filter('1.1.1.1', 'uid', 'PUT', '/users/1'), Helper.PASS)
      assert.is_equal(shield:filter('1.1.1.1', 'uid', 'DELETE', '/users/1'), Helper.BLOCK)
      assert.is_equal(shield:filter('1.1.1.1', 'uid', 'DELETE', '/users/2'), Helper.BLOCK)

      s.callback = function() return 1015 end
      assert.is_equal(shield:filter('1.1.1.1', 'uid', 'PUT', '/users/1'), Helper.PASS)
      assert.is_equal(shield:filter('1.1.1.1', 'uid', 'PUT', '/users/2'), Helper.BLOCK)
      assert.is_equal(shield:filter('1.1.1.1', 'uid', 'GET', '/users/2'), Helper.PASS)
    end)

    it('should ignore * limit if require break_shield path /status', function()
      local s = spy.on(Helper, 'time')
      s.callback = function() return 1000 end

      for i = 1, 5 do
        assert.is_equal(shield:filter('1.1.1.1', 'uid', 'GET', '/status'), Helper.BREAK)
      end

      -- Use PUT method
      for i = 1, 3 do
        assert.is_equal(shield:filter('1.1.1.1', 'uid', 'PUT', '/status'), Helper.PASS)
      end

      assert.is_equal(shield:filter('1.1.1.1', 'uid', 'PUT', '/status'), Helper.BLOCK)
      assert.is_equal(shield:filter('1.1.1.1', 'uid', 'GET', '/status'), Helper.BREAK)
    end)

    it('should not raise error if redis connect failed', function()
      local shield = PathShield.new({config = {redis_host = '1.1.1.1'}}, config)
      for i = 1, 3 do
        assert.is_equal(shield:filter('1.1.1.1', 'uid', 'GET', '/'), Helper.PASS)
      end
    end)
  end)
end)
