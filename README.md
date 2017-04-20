WebShield
===========

APIGateway Base OpenResty 


## Usage

/path/to/nginx.conf

```
http {
  init_by_lua_file 'lualib/init.lua';

  server {
    set_real_ip_from 192.168.0.1/16;
    set_real_ip_from 10.0.0.1/8;
    set_real_ip_from 127.0.0.1/16;
    set_real_ip_from 172.0.0.1/8;

    real_ip_recursive on;
    real_ip_header 'X-Real-IP';

    access_by_lua_file 'lualib/access_checker.lua';

    proxy_pass http://xxx;
  }
}
```

Run docker

```
$ docker build -t nginx_gateway:latest ./ 
$ docker run -v /path/to/nginx.conf:/openresty/conf/nginx.conf -e REDIS_HOST={IP} -e MYSQL_HOST={IP} MYSQL_PASSWORD={PASSWORD} nginx_gateway
```


### Support env variables

* `REDIS_HOST`: default `127.0.0.1`
* `REDIS_PORT`: default 6379
* `MYSQL_CONFIG`: empty, if != nil then fetch config from mysql
* `MYSQL_HOST`: default 127.0.0.1
* `MYSQL_PORT`: default 3306
* `MYSQL_USER`: default web_shield
* `MYSQL_PASS`: default empty
* `MYSQL_DB`: default web_shield
* `CONFIG_REFRESH_INTERVAL`: default `60` seconds, read config from mysql


### Custom access checker

```
local ConfigStore = require 'resty.web_shield.config_store'

local web_shield = require('resty.web_shield').new(
  {redis_host = '127.0.0.1', redis_port = 6379},
  ConfigStore.fetch({mysql = {database = 'web_shield'}) or shield_config
)
web_shield:check(
  ngx.var.realip_remote_addr, ngx.header['X-User-ID'],
  ngx.var.request_method, ngx.var.uri
)
```


### Shield Config

```
{
  order = 'and',
  shields = {
    {
      name = 'ip_shield',
      config = {
        whitelist = { '127.0.0.1', '192.168.0.1/16', '172.0.0.1/8' },
        blacklist = { '123.123.123.123/16' }
      }
    },

    // path whitelist
    {
      name = 'path_shield',
      config = {
        threshold = {
          {
            matcher = {method = "GET", path = "/home"},
            period = 1,
            limit = 9999 // very large value ≈ whitelist
          },
          { matcher = {method = "GET", path = "/status"}, period = 1, limit = 9999 }
        }
      }
    },

    {
      name = 'path_shield',
      config = {
        threshold = {
          // level 1
          {
            matcher = {
              method = "*", // request methods, * GET POST, PUT DELETE
              path = "*"
            },
            period = 20, // seconds
            limit = 15 // max requests
          },
          // level 2
          { matcher = {method = {"*"}, path = "*"}, period = 60, limit = 30 },
          // level 3
          { matcher = {method = ["*"], path = "*"}, period = 120, limit = 45 },

          // overwrite level rule
          {
            matcher = {method = {"POST", "PUT", "DELETE"}, path = "*"}, period = 60, limit = 10
          },
          {
            matcher = {method = "POST", path = "/api/v1/sessions"}, period = 120, limit = 6
          },

          // break
          {
            matcher = {method = "GET", path = "/api/v1/data"},
            period = 20, limit = 5,
            break_shield = true // skip other shield
          },
        ]
      }
    }
  }
}
```


### Nested Shields

```
{
  order = 'and',
  shields = {
    {
      name = 'control_shield',
      config = {
        order = 'or',
        shields = {
          {name = 'ip', config = {...}}
          {name = 'control_shield', config = {...}}
        }
      }
    },
    { name = 'xx_shield', config = {...} }
  }
```

## Limitations

* period use unify time


## TODO LIST

- [x] Proxy forwarded whitelist
- [x] Redis config
- [x] IPShield support mask
- [x] dynamic update config
- [ ] collect log, alert

