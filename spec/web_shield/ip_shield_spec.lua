describe("IPShield", function()
  local IPShield = require 'resty.web_shield.ip_shield'
  local Helper = require 'resty.web_shield.helper'
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

      -- TODO IP mask
      -- assert.is_equal(shield:filter('123.123.1.1', '123', 'GET', '/asdf'), Helper.BLOCK)
      -- assert.is_equal(shield:filter('123.123.1.123', '1123', 'GET', '/oa'), Helper.BLOCK)
      assert.is_equal(shield:filter('123.123.2.123', '1123', 'GET', '/oa'), Helper.PASS)
    end)

    it("should block ip if it in blacklist and whitelist", function()
      assert.is_equal(shield:filter('1.1.1.1', 'uid', 'GET', '/'), Helper.BLOCK)
    end)

    it("should pass and break filter if ip in whitelist", function()
      assert.is_equal(shield:filter('127.0.0.1', 'uid', 'GET', '/'), Helper.BREAK)
      assert.is_equal(shield:filter('127.0.0.1', '123', 'GET', '/asdf'), Helper.BREAK)

      -- TODO IP mask
      -- assert.is_equal(shield:filter('192.168.1.1', '123', 'GET', '/asdf'), Helper.BREAK)
      -- assert.is_equal(shield:filter('192.168.255.1', '123', 'GET', '/asdf'), Helper.BREAK)
      assert.is_equal(shield:filter('192.169.1.1', '123', 'GET', '/asdf'), Helper.PASS)
    end)
  end)
end)
