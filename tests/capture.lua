-- Capture startup failures too. Neovim can otherwise exit successfully after a Lua error.
_G.test_errors = {}
local notify = vim.notify
vim.notify = function(message, level, opts)
  if level and level >= vim.log.levels.WARN then
    test_errors[#test_errors + 1] = tostring(message)
  end
  return notify(message, level, opts)
end
