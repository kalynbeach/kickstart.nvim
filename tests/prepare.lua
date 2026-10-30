local ok, err = xpcall(function()
  require('lazy').restore { wait = true }
  require('lazy').load { plugins = { 'mason.nvim' } }
  local registry = require 'mason-registry'
  local refreshed = false
  registry.refresh(function(success)
    assert(success, 'Mason registry refresh failed')
    refreshed = true
  end)
  assert(
    vim.wait(120000, function()
      return refreshed
    end),
    'Mason registry refresh timed out'
  )
  local handles = {}
  local bin = vim.fn.stdpath 'data' .. '/mason/bin/'
  for _, name in ipairs { 'lua-language-server', 'stylua' } do
    if vim.fn.executable(bin .. name) == 0 then
      handles[#handles + 1] = registry.get_package(name):install()
    end
  end
  assert(
    vim.wait(180000, function()
      for _, handle in ipairs(handles) do
        if not handle:is_closed() then
          return false
        end
      end
      return true
    end),
    'Mason tool installation timed out'
  )
  assert(vim.fn.executable(bin .. 'lua-language-server') == 1, 'Lua language server installation failed')
  assert(vim.fn.executable(bin .. 'stylua') == 1, 'StyLua installation failed')

  local ts = require 'nvim-treesitter'
  local expected = require('plugins.treesitter')[1].opts.parsers
  assert(
    vim.wait(180000, function()
      local installed = ts.get_installed 'parsers'
      local queries = ts.get_installed 'queries'
      for _, language in ipairs(expected) do
        if not vim.tbl_contains(installed, language) or not vim.tbl_contains(queries, language) then
          return false
        end
      end
      return true
    end),
    'Parser installation timed out'
  )
  assert(#test_errors == 0, table.concat(test_errors, '\n'))
  assert(vim.v.errmsg == '', vim.v.errmsg)
  print 'Plugin restore, tools, and parsers: OK'
end, debug.traceback)
if not ok then
  print(err)
  vim.cmd 'cquit 1'
end
vim.cmd 'qa!'
