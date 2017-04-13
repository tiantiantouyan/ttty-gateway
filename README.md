WebShield
===========

Base OpenResty


## Usage

```
local web_shield = require('resty.web_shield').new(
  {redis_host = '127.0.0.1', redis_port = 6379},
  shield_config
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
    name = 'ip_shield',
    config = {
      whitelist = { '127.0.0.1', '192.168.0.1/16', '172.0.0.1/8' },
      blacklist = { '123.123.123.123/16' }
    },
    
    name = 'path_shield',
    config = {
      threshold = {
        // level 1
        {
          condition = {
            method = "*", // request methods, * GET POST, PUT DELETE
            path = "*"
          },
          period = 20, // seconds
          limit = 15 // max requests
        },
        // level 2
        { condition = {method = {"*"}, path = "*"}, period = 60, limit = 30 },
        // level 3
        { condition = {method = ["*"], path = "*"}, period = 120, limit = 45 },

        // overwrite level rule
        {
          condition = {method = {"POST", "PUT", "DELETE"}, path = "*"}, period = 60, limit = 10
        },
        {
          condition = {method = "POST", path = "/api/v1/sessions"}, period = 120, limit = 6
        },

        // path whitelist
        {
          condition = {method = "GET", path = "/home"},
          period = 1,
          limit = 9999 // very large value ≈ whitelist
        },

        // break
        {
          condition = {method = "GET", path = "/api/v1/data"},
          period = 20, limit = 5,
          break_shield = true // skip other shield
        },
      ]
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

## Nginx

lua package path

```
http {
  lua_package_path "/openresty_dir/lualib/?.lua;;";
}
```

server

```
upstream backend {
  server 192.168.1.1:8080;
}

server {
  # ...

  location / {
    set_real_ip_from 192.168.0.1/16;
    set_real_ip_from 10.0.0.1/8;
    set_real_ip_from 127.0.0.1/16;
    set_real_ip_from 172.0.0.1/8;

    real_ip_recursive on;
    real_ip_header 'X-Real-IP';

    access_by_lua_file 'lualib/access_checker.lua';
    
    proxy_pass http://backend;
  }

}
```


## Limitations

* period use unify time


## TODO LIST

- [ ] Proxy forwarded whitelist
- [x] Redis config
- [x] IPShield support mask
- [ ] dynamic update config
- [ ] collect log, alert

