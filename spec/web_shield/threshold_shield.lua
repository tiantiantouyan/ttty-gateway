describe("ThresholdShield", function()
  local ThresholdShield = require 'resty.web_shield.threshold_shield'

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
        {matcher = {method = {'PUT', "DELETE"}, path = '/users/*'}, period = 5, limit = 1},
        {
          matcher = {method = {'*'}, path = '*', header = {ua = 'hack'}},
          period = 5, limit = 1
        }
      }
    }
    local web_shield = WebShield.new({redis = {}}, {})
    local shield = ThresholdShield.new(web_shield, config)

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
      local htime = Helper.time

      Helper.time = function() return 1000 end
      assert.is_equal(shield:filter('1.1.1.1', 'uid', 'GET', '/'), Helper.PASS)
      assert.is_equal(shield:filter('1.1.1.1', 'uid', 'GET', '/'), Helper.PASS)
      assert.is_equal(shield:filter('1.1.1.1', 'uid', 'GET', '/'), Helper.PASS)

      Helper.time = function() return 1005 end
      assert.is_equal(shield:filter('1.1.1.1', 'uid', 'GET', '/'), Helper.PASS)
      assert.is_equal(shield:filter('1.1.1.1', 'uid', 'GET', '/'), Helper.PASS)
      assert.is_equal(shield:filter('1.1.1.1', 'uid', 'GET', '/'), Helper.BLOCK)
      Helper.time = htime
    end)

    it('should block if over /users/* limit', function()
      local htime = Helper.time

      Helper.time = function() return 1000 end
      assert.is_equal(shield:filter('1.1.1.1', 'uid', 'PUT', '/users/1'), Helper.PASS)
      assert.is_equal(shield:filter('1.1.1.1', 'uid', 'DELETE', '/users/1'), Helper.BLOCK)
      assert.is_equal(shield:filter('1.1.1.1', 'uid', 'DELETE', '/users/2'), Helper.BLOCK)

      Helper.time = function() return 1015 end
      assert.is_equal(shield:filter('1.1.1.1', 'uid', 'PUT', '/users/1'), Helper.PASS)
      assert.is_equal(shield:filter('1.1.1.1', 'uid', 'PUT', '/users/2'), Helper.BLOCK)
      assert.is_equal(shield:filter('1.1.1.1', 'uid', 'GET', '/users/2'), Helper.PASS)

      Helper.time = htime
    end)

    it('should ignore * limit if require break_shield path /status', function()
      local htime = Helper.time
      Helper.time = function() return 1000 end

      for i = 1, 5 do
        assert.is_equal(shield:filter('1.1.1.1', 'uid', 'GET', '/status'), Helper.BREAK)
      end

      -- Use PUT method
      for i = 1, 3 do
        assert.is_equal(shield:filter('1.1.1.1', 'uid', 'PUT', '/status'), Helper.PASS)
      end

      assert.is_equal(shield:filter('1.1.1.1', 'uid', 'PUT', '/status'), Helper.BLOCK)
      assert.is_equal(shield:filter('1.1.1.1', 'uid', 'GET', '/status'), Helper.BREAK)

      Helper.time = htime
    end)

    it('should not raise error if redis connect failed', function()
      local shield = ThresholdShield.new({config = {redis = {host = '1.1.1.1'}}}, config)
      for i = 1, 3 do
        assert.is_equal(shield:filter('1.1.1.1', 'uid', 'GET', '/'), Helper.PASS)
      end
    end)

    it('should PASS if header not matched', function()
      config.threshold[2].matcher.header = {ua = '^ua$'}
      for i = 1, 4 do
        assert.is_equal(
          shield:filter('1.1.1.1', 'uid', 'GET', '/', {ua = 'ua2'}), Helper.PASS
        )
      end
      config.threshold[2].matcher.header = nil
    end)

    it('should exec filter if header match', function()
      assert.is_equal(shield:filter('1.1.1.1', 'uid', 'GET', '/', {ua = 'hack'}), Helper.PASS)
      assert.is_equal(
        shield:filter('1.1.1.1', 'uid', 'GET', '/', {ua = 'hack'}), Helper.BLOCK
      )
    end)

    it('should not raise error if header is invalid', function()
      config.threshold[1].matcher.header = 'asdf'
      assert.is_equal(shield:filter('1.1.1.1', 'uid', 'GET', '/', 'asdf'), Helper.PASS)
      config.threshold[1].matcher.header = nil
    end)
  end)
end)
