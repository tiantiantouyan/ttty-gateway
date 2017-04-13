WebShield
===========

Base OpenResty


## Usage

```
require('resty.web_shield').new(
  {redis_host = '127.0.0.1', redis_port = 6379},
  shield_config
):check(
  ip, user_identifier, ngx.var.request_method, ngx.var.uri
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


## Limitations

* period use unify time


## TODO LIST

- [ ] Proxy forwarded whitelist
- [x] Redis config
- [x] IPShield support mask
- [ ] dynamic update config
- [ ] collect log, alert

