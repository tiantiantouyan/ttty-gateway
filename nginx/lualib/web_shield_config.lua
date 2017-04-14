ANY = {'*'}
READ = {'GET'}
WRITE = {'POST', 'PUT', 'DELETE'}

return {
  order = 'and',
  shields = {
    -- ip whitelist blacklist
    {
      name = 'ip_shield',
      config = {
        whitelist = {'127.0.0.1', '192.168.1.1/16', '172.17.0.1/16'},
        blacklist = {'1.2.3.4', '1.1.1.1/16'}
      }
    },

    -- path whitelist
    {
      name = 'path_shield',
      config = {
        threshold = {
          {
            matcher = {method = ANY, path = '/api/status'},
            period = 1, limit = 9999, break_shield = true
          },
          {
            matcher = {method = ANY, path = '/'},
            period = 10, limit = 10, break_shield = true
          }
        }
      }
    },

    -- global threshold
    {
      name = 'path_shield',
      config = {
        threshold = {
          -- level 1
          {matcher = {method = READ, path = '*'}, period = 20, limit = 15},
          {matcher = {method = WRITE, path = '*'}, period = 20, limit = 7},
          -- level 2
          {matcher = {method = READ, path = '*'}, period = 60, limit = 30},
          {matcher = {method = WRITE, path = '*'}, period = 60, limit = 14},
          -- level 3
          {matcher = {method = READ, path = '*'}, period = 120, limit = 45},
          {matcher = {method = WRITE, path = '*'}, period = 120, limit = 21},

          -- login
          {matcher = {method = {'POST'}, path = '/api/v*/sessions'}, period = 300, limit = 10},
          -- register
          {matcher = {method = {'POST'}, path = '/api/v*/users'}, period = 300, limit = 10},
        }
      }
    }
  }
}

