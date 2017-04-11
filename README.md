WebShield
===========


## Usage

```
require('resty.web_shield').new(config):check(
  ip, user_identifier, ngx.var.request_method, ngx.var.uri
)
```


### Config

```
return {
  ip_shield = {
    whitelist = {
      '127.0.0.1',
      '192.168.0.1/16',
      '172.0.0.1/8'
    },
    blacklist = {
      '123.123.123.123/16',
    }
  },
  path_shield = {
    threshold = {
      // level 1
      {
        condition = {
          method = "*", // require methods, * GET POST, PUT DELETE
          path = "*"
        },
        period = 20, // seconds
        limit = 15 // max requests
      },
      // level 2
      {
        condition = {method = {"*"}, path = "*"},
        period = 60,
        limit = 30
      },
      // level 3
      {
        condition = {method = ["*"], path = "*"},
        period = 120,
        limit = 45
      },

      // overwrite level rule
      {
        condition = {method = {"POST", "PUT", "DELETE"}, path = "*"},
        period = 60,
        limit = 10
      },
      {
        condition = {method = "POST", path = "/api/v1/sessions"},
        period = 120,
        limit = 6 //
      },

      // path whitelist
      {
        condition = {method = "GET", path = "/home"},
        period = 1,
        limit = 9999 // very large value ≈ whitelist
      },

      // path sensitive
      {
        condition = {method = "GET", path = "/api/v1/data"},
        period = 20,
        limit = 5, // very large value ≈ whitelist
        path_sensitive = true, // very large value ≈ whitelist
      },

      // break
      {
        condition = {method = "GET", path = "/api/v1/data"},
        period = 20,
        limit = 5, // very large value ≈ whitelist
        break = true, // skip other shield
      },
    ]
  }
}

```

