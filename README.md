TTTYGateway
===========

基于 OpenResty 的 APIGateway, 针对用户限制请求频率，设置 IP/Path 黑白名单

## 可以做什么

* 设置 API 请求的 IP 黑名单及白名单
* 针对 Path 设置请求的白名单
* 根据 IP 针对 Path 设置请求频率限制
* 根据 User 针对 Path 设置请求频率限制
* 为 Prometheus 提供简单的 Nginx 状态信息

Path: 可以对指定请求方法(GET POST PUT DELETE)及请求的路径进行匹配，路径支持简单的通配符
User: 代码中自由定义，可以未登陆时使用 IP，登陆后使用用户 ID 或 TOKEN 等 


## 使用

## Nginx config

参考 `nginx/conf/nginx.conf`


### Server scope

```
http {
  lua_package_path "/path/to/ttty-gateway/nginx/lualib/?.lua;;";
  init_by_lua_file 'lualib/init.lua'; # load gateway config

  server {
    listen 80;

    set_real_ip_from 127.0.0.1;
    set_real_ip_from 192.168.0.0/16;
    set_real_ip_from 10.0.0.0/8;
    set_real_ip_from 172.0.0.0/12;

    real_ip_header 'X-Forwarded-For';
    real_ip_recursive on;

    -- 运行检查器
    access_by_lua_file 'lualib/access_checker.lua'; # gatway checker

    location / {
      proxy_pass http://xxx;
    }
  }
}
```

### location scope 

```
http {
  lua_package_path "/path/to/ttty-gateway/nginx/lualib/?.lua;;";
  init_by_lua_file 'lualib/init.lua'; # load gateway config

  server {
    listen 80;

    location / {
      set_real_ip_from 127.0.0.1;
      set_real_ip_from 192.168.0.0/16;
      set_real_ip_from 10.0.0.0/8;
      set_real_ip_from 172.0.0.0/12;

      real_ip_header 'X-Forwarded-For';
      real_ip_recursive on;

      access_by_lua_file 'lualib/access_checker.lua'; # gatway checker
      proxy_pass http://xxx;
    }
  }
}
```

### Run

```
$ openresty -p /path/to/ttty-gateway
```

### Docker

```
$ docker build ./ -t ttty_gateway:latest
$ docker run -v /path/to/your/nginx.conf:/openresty/conf/nginx.conf -e REDIS_HOST={IP} -e MYSQL_HOST={IP} MYSQL_PASSWORD={PASSWORD} nginx_gateway
```

## 默认配置支持的 ENV

默认配置路径 `nginx/lualib/web_shield_config.lua`

* `REDIS_HOST`: default `127.0.0.1`
* `REDIS_PORT`: default 6379
* `REDIS_POOL_SIZE`: default 100
* `REDIS_POOL_TIMEOUT`: default 10 * 1000, 毫秒
* `MYSQL_CONFIG`: empty, 如果不为空的话， MYSQL 中又有相关的配置，直接读取 MYSQL 配置
* `MYSQL_HOST`: default 127.0.0.1
* `MYSQL_PORT`: default 3306
* `MYSQL_USER`: default web_shield
* `MYSQL_PASSWORD`: default empty
* `MYSQL_DB`: default web_shield
* `MYSQL_POOL_SIZE`: default 100
* `MYSQL_POOL_TIMEOUT`: default 10 * 1000, 毫秒
* `CONFIG_REFRESH_INTERVAL`: default `30` seconds, refresh MYSQL config


## 定制 IP 及 用户标识

默认的为 `nginx/lualib/access_checker.lua`
默认的应该不会适合你，使用你自己的方式取得  user-ip, user-id， 也可以使用自己的方式加载配置

```
-- 加载默认的配置 nginx/lualib/web_shield_config, 支持上面提到的 ENV 
-- 当然你可以修改这个配置，具体后面有说明
local my_config = require('web_shield_config') 
local web_shield = require('resty.web_shield').new(my_config.web_shield, my_config.shield)
  
local ip = ngx.var.remote_addr -- 使用了 nginx realip 可以直接拿到用户的 ip
local uid = ngx.header['X-User-ID'] -- 使用你自己的方式取得用户的唯一标识，像 id, token 

-- 调用 check ，被 block 就会返回 false ，然后就返回 block 信息
if not web_shield:check(ip, uid ngx.var.request_method, ngx.var.uri) then
  ngx.status = ngx.HTTP_TOO_MANY_REQUESTS
  ngx.say("Too many requests")
  ngx.exit(ngx.HTTP_TOO_MANY_REQUESTS)
end
```


## 规则配置(Shield Config)

参照 `nginx/lualib/web_shield_config.lua` 中的 shield 数据

### Shields

对应配置中的 `name`

* `control_shield`: 最外层默认是一个 control_shield，使用 `order` 来控制 `shields` 的运行逻辑
* `ip_shield`: 关于 IP 的黑白名单
* `path_shield`: 基于用户及请求路径的请求限制

### Example

```
{ -- 最外层的 control_shiled
  order = 'and', -- 所有 shields 中的模块判断通过了，请求才被放行; `or` 则只要一个通过就放行
  shields = {
    {
      name = 'ip_shield', -- shield name，对面的配置在 config 中
      config = {
        whitelist = { '127.0.0.1', '192.168.0.1/16', '172.0.0.1/8' },
        blacklist = { '123.123.123.123/16' }
      }
    },

    -- path whitelist
    {
      name = 'path_shield',
      config = {
        threshold = {
          {
            matcher = {
              method = {"GET"}, -- 支持 `*` 及所有 nginx 支持的 request_method
              path = "/home" -- 支持 * 匹配任意数量的任意字符
            },
            period = 1, -- 限制周期，单位为秒
            limit = 9999, -- period 周期内最大请求次数，使用一个非常大的值，相当于白名单
            break_shield = true -- 当通过此 shield 时，不再执行其它的 shield 判断了，直接通过
          },
          {
            matcher = {method = {"GET"}, path = "/status"},
            period = 1, limit = 9999, break_shield = true 
          }
        }
      }
    },

    {
      name = 'path_shield',
      config = {
        threshold = {
          -- level 1
          {
            matcher = {
              method = {"*"}, -- request methods, * GET POST, PUT DELETE
              path = "*"
            },
            period = 20,
            limit = 15
          },
          -- level 2
          { matcher = {method = {"*"}, path = "*"}, period = 60, limit = 30 },
          -- level 3
          { matcher = {method = {"*"}, path = "*"}, period = 120, limit = 45 },

          {
            matcher = {method = {"POST", "PUT", "DELETE"}, path = "/api/*/users"},
            period = 60, limit = 10
          },
          {
            matcher = {method = {"POST"}, path = "/api/v1/sessions"}, period = 120, limit = 6
          },
        ]
      }
    }
  }
}
```


### 嵌套 shields 逻辑（不推荐使用）

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


## Mysql config

DB 需要创建 `kvs` 表，存在 `key` `val` 两列，并且存在下面四条数据，val 为 JSON 字符串

key `web_shield/ip_whitelist`

```
["127.0.0.1", "192.168.1.1/16"]
```

key `web_shield/ip_blacklist`

```
["1.2.3.4', "123.123.123.123/24"]
```

key `web_shield/path_whitelist`, 格式同 `path_shield` config

```
[
  {
    "matcher": {"method": ["GET"], "path": "/w/*"},
    "limit": 5, "period": 3, "break_shield": true
  }
]
```

key `web_shield/path_threshold`， 格式同 `path_shield` config

```
[
  {"matcher": {"method": ["GET"], "path": "/api/*"}, "limit": 10, "period": 5},
  {"matcher": {"method": ["PUT", "POST"], "path": "/api/*"}, "limit": 5, "period": 3}
]
```

可以考虑简单的 Mysql 配置管理项目 [ttty-manager](https://github.com/tiantiantouyan/ttty-manager)


## TODO

* 目前流量是由 redis 来统计的，考虑是否可以结合 resty-limit-traffic 使用本地内存来实现一个更高效率的方案
* path_shield 支持 header 匹配，比如限制指定 ua 请求量为 3req/5s，或是非指定 ua 请求量为 5req/10s


## Development

* lua 5.1 or luajit 
* `brew install OpenResty`
* `luarocks install busted --local`
* mysql database `ngx_test`, empty root password


### Testing

```
$ bin/busted
```

