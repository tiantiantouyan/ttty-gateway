describe("IPShield", function()
  local IPShield = require 'resty.web_shield.ip_shield'
  local config = {
    whitelist = {'127.0.0.1', '192.168.0.1/16', '1.1.1.1'},
    blacklist = {'1.2.3.4', '123.123.1.1/24', '1.1.1.1'}
  }

  describe("filter", function()
    local shield = IPShield.new(config)

    it("should pass normal ip", function()
      assert.is_equal(shield:filter('129.1.1.1', 'uid', 'GET', '/'), Helper.PASS)
      assert.is_equal(shield:filter('129.1.1.2', 'asdf', 'GET', '/other'), Helper.PASS)
    end)

    it("should block ip if it in blacklist", function()
      assert.is_equal(shield:filter('1.2.3.4', 'uid', 'GET', '/'), Helper.BLOCK)
      assert.is_equal(shield:filter('1.2.3.4', '???', 'GET', '/p2'), Helper.BLOCK)

      assert.is_equal(shield:filter('123.123.1.1', '123', 'GET', '/asdf'), Helper.BLOCK)
      assert.is_equal(shield:filter('123.123.1.123', '1123', 'GET', '/oa'), Helper.BLOCK)
      assert.is_equal(shield:filter('123.123.2.123', '1123', 'GET', '/oa'), Helper.PASS)
    end)

    it("should block ip if it in blacklist and whitelist", function()
      assert.is_equal(shield:filter('1.1.1.1', 'uid', 'GET', '/'), Helper.BLOCK)
    end)

    it("should pass and break filter if ip in whitelist", function()
      assert.is_equal(shield:filter('127.0.0.1', 'uid', 'GET', '/'), Helper.BREAK)
      assert.is_equal(shield:filter('127.0.0.1', '123', 'GET', '/asdf'), Helper.BREAK)

      assert.is_equal(shield:filter('192.168.1.1', '123', 'GET', '/asdf'), Helper.BREAK)
      assert.is_equal(shield:filter('192.168.255.1', '123', 'GET', '/asdf'), Helper.BREAK)
      assert.is_equal(shield:filter('192.169.1.1', '123', 'GET', '/asdf'), Helper.PASS)
    end)
  end)

  describe('ip_match', function()
    it('should return true if match', function()
      assert.is_equal(IPShield.ip_match('192.168.1.1', '192.168.1.1'), true)
      assert.is_equal(IPShield.ip_match('192.168.1.1', '192.168.1.2'), false)

      assert.is_equal(IPShield.ip_match('192.168.1.1/24', '192.168.1.1'), true)
      assert.is_equal(IPShield.ip_match('192.168.1.1/24', '192.168.1.2'), true)
      assert.is_equal(IPShield.ip_match('192.168.1.1/24', '192.168.1.255'), true)
      assert.is_equal(IPShield.ip_match('192.168.1.1/24', '192.168.2.255'), false)

      assert.is_equal(IPShield.ip_match('192.168.1.1/8', '192.169.2.2'), true)
      assert.is_equal(IPShield.ip_match('192.168.1.1/8', '193.169.2.2'), false)
    end)
  end)

  describe("ip2int", function()
    it('should return int value', function()
      assert.is_equal(IPShield.ip2int('127.0.0.1'), 2130706433)
      assert.is_equal(IPShield.ip2int('127.0.0.2'), 2130706434)
      assert.is_equal(IPShield.ip2int('1.2.3.4'), 16909060)
      assert.is_equal(IPShield.ip2int('255.255.255.255'), -1)
    end)
  end)
end)
