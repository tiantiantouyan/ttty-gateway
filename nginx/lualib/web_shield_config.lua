ANY = {'*'}
READ = {'GET'}
WRITE = {'POST', 'PUT', 'DELETE'}

return {
  web_shield = {
    redis = {
      host = os.getenv('REDIS_HOST') or '127.0.0.1',
      port = tonumber(os.getenv('REDIS_PORT')) or 6379
    }
  },

  config_store = {
    enabled = os.getenv('MYSQL_CONFIG'),
    mysql = {
      host = os.getenv('MYSQL_HOST') or '127.0.0.1',
      port = tonumber(os.getenv('MYSQL_PORT')) or 3306,
      user = os.getenv('MYSQL_USER') or 'web_shield',
      password = os.getenv('MYSQL_PASSWORD'),
      database = os.getenv('MYSQL_DB') or 'web_shield'
    },
    refresh_interval = tonumber(os.getenv('CONFIG_REFRESH_INTERVAL')) or 30
  },

  shield = {
    order = 'and',
    shields = {
      -- ip whitelist blacklist
      {
        name = 'ip_shield',
        config = {
          whitelist = {'127.0.0.1', '192.168.0.1/16', '172.17.0.1/12', '10.0.0.0/8'},
          blacklist = {}
        }
      },

      -- path whitelist
      {
        name = 'path_shield',
        config = {
          threshold = {
            -- {
            --   matcher = {method = ANY, path = '/'},
            --   period = 10, limit = 9999, break_shield = true
            -- }
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

          }
        }
      }
    }
  }
}

