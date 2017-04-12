local M = {}

local log_level = {
  debug = 'DEBUG',
  info = 'INFO',
  warn = 'WARN',
  err = 'ERR'
}

function M.log(level, msg)
  if ngx and ngx.log then
    ngx.log(ngx[log_level[level]], msg)
  else
    print("[" .. log_level[level] .. '] ' .. msg)
  end
end

function M.debug(msg)
  M.log('debug', msg)
end

function M.info(msg)
  M.log('info', msg)
end

function M.warn(msg)
  M.log('warn', msg)
end

function M.err(msg)
  M.log('err', msg)
end

return M

