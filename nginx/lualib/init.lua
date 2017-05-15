local config = require 'web_shield_config'

-- lua_shared_dict prometheus_metrics 10M;
prometheus = require('prometheus').init('prometheus_metrics')
metric_requests = prometheus:counter(
  'nginx_http_requests_total', 'Number of HTTP requests',
  {'host', 'path', 'status'}
)
metric_request_users = prometheus:counter(
  'nginx_http_request_users_total', 'Number of HTTP request users',
  {'host', 'ip', 'uid', 'status'}
)
metric_latency = prometheus:histogram(
  'nginx_http_request_duration_second', 'HTTP request latency', {'host'}
)
metric_connections = prometheus:gauge(
  'nginx_http_connections', 'Number of HTTP connections', {'state'}
)

