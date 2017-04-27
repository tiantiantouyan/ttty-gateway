local host = ngx.var.host:gsub("^www.", "")
metric_requests:inc(1, {host, ngx.var.uri, ngx.var.status})
metric_request_users:inc(
  1, {host, ngx.ctx.web_shield_ip, ngx.ctx.web_shield_uid, ngx.var.status}
)
metric_latency:observe(ngx.now() - ngx.req.start_time(), {host})

