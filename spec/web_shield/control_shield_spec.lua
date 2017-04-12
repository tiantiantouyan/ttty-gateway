describe("ControlShield", function()
  local ControlShield = require 'resty.web_shield.control_shield'
  local Helper = require 'resty.web_shield.helper'

  local config = {
    order = 'and',
    shields = {
      {
        name = 'ip_shield',
        config = {
          whitelist = {'192.168.1.1'},
          blacklist = {'1.2.3.4', '1.0.0.3', '1.1.2.2'}
        }
      },
      {
        name = 'ip_shield',
        config = {
          whitelist = {'1.0.0.2', '1.0.0.3'},
          blacklist = {'192.168.1.1', '2.2.2.2', '1.1.2.2'}
        }
      },
    }
  }

  local function req_info(ip)
    return ip, 'uid', 'GET', '/'
  end

  describe("filter", function()
    describe("order = 'and'", function()
      config.order = 'and'
      local shield = ControlShield.new(config)

      it('should pass ip if all shields is pass', function()
        assert.is_equal(shield:filter(req_info('1.2.2.2')), Helper.PASS)
      end)

      it('should block ip if any shield block', function()
        assert.is_equal(shield:filter(req_info('1.2.3.4')), Helper.BLOCK)
        assert.is_equal(shield:filter(req_info('2.2.2.2')), Helper.BLOCK)
        assert.is_equal(shield:filter(req_info('1.0.0.3')), Helper.BLOCK)
      end)

      it('should return break if first shield is break', function()
        assert.is_equal(shield:filter(req_info('192.168.1.1')), Helper.BREAK)
      end)
    end)

    describe("order = 'or'", function()
      config.order = 'or'
      local shield = ControlShield.new(config)

      it('should pass ip if any shields is pass', function()
        assert.is_equal(shield:filter(req_info('2.2.2.2')), Helper.PASS)
        assert.is_equal(shield:filter(req_info('1.2.3.4')), Helper.PASS)
        assert.is_equal(shield:filter(req_info('1.0.0.2')), Helper.PASS)
      end)

      it('should break if first shields is break', function()
        assert.is_equal(shield:filter(req_info('192.168.1.1')), Helper.BREAK)
      end)

      it('should block if all shields block ip', function()
        assert.is_equal(shield:filter(req_info('1.1.2.2')), Helper.BLOCK)
      end)
    end)

    describe("nested control_shield", function()
      config.order = 'and'
      table.insert(config.shields, {
        name = 'control_shield',
        config = {
          order = 'and',
          shields = {
            {name = 'ip_shield', config = {whitelist = {'111.1.1.1'}, blacklist = {}}},
            {name = 'ip_shield', config = {whitelist = {'2.2.2.3'}, blacklist = {'3.3.3.3'}}}
          }
        }
      })
      local shield = ControlShield.new(config)

      it('should pass if all pass', function()
        assert.is_equal(shield:filter(req_info('1.2.2.2')), Helper.PASS)
        assert.is_equal(shield:filter(req_info('111.1.1.2')), Helper.PASS)
      end)

      it('should break if nested shield break', function()
        assert.is_equal(shield:filter(req_info('111.1.1.1')), Helper.BREAK)
        assert.is_equal(shield:filter(req_info('2.2.2.3')), Helper.BREAK)
      end)

      it('should block if nested shield block', function()
        assert.is_equal(shield:filter(req_info('3.3.3.3')), Helper.BLOCK)
      end)
    end)
  end)
end)

