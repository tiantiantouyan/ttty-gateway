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
end)
