local config = require 'web_shield_config'
local cjson = require 'cjson'

ngx.header['Content-Type'] = 'text/json'

if ngx.var.request_method == 'GET' then
  ngx.print(cjson.encode(config))
elseif ngx.var.request_method == 'POST' then
  ngx.req.read_body()
  local req_args =  ngx.req.get_post_args()

  if req_args then
    config.shields[1].config.whitelist = req_args.whitelist
    config.shields[1].config.blacklist = req_args.blacklist
  end

  ngx.redirect('/web-shield/index.html')
else
  ngx.status = ngx.HTTP_NOT_FOUND
end

