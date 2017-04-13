local M = {
  output_level = 2,
  log_dev = 'auto', -- auto, stdout, null
  log_prefix = '[WebShield] '
}

local log_names = {
  debug = 'DEBUG',
  info = 'INFO',
  warn = 'WARN',
  err = 'ERR'
}

M.levels = {
  debug = 1,
  info = 2,
  warn = 3,
  err = 4
}

M.log_devs = {
  ngx = function(level, msg)
    ngx.log(ngx[log_names[level]], M.log_prefix .. msg)
  end,
  stdout = function(level, msg)
    if M.levels[level] < M.output_level then return end
    print("[" .. log_names[level] .. '] ' .. M.log_prefix .. msg)
  end,
  null = function(level, msg) end
}


function M.set_log_dev(dev)
  M.log_dev = dev or 'auto'

  if M.log_dev == 'auto' and ngx and ngx.log then
    M.log = M.log_devs.ngx
  else
    M.log = M.log_devs.stdout
  end
end
M.set_log_dev('auto')

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

