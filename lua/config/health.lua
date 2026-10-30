local M = {}

function M.check()
  vim.health.start 'Neovim configuration'
  if vim.fn.has 'nvim-0.12' == 1 then
    vim.health.ok('Neovim ' .. tostring(vim.version()))
  else
    vim.health.error 'Neovim 0.12 or newer is required'
  end
  for _, executable in ipairs { 'git', 'make', 'cc', 'unzip', 'curl', 'tar', 'rg', 'tree-sitter' } do
    if vim.fn.executable(executable) == 1 then
      vim.health.ok('Found ' .. executable)
    else
      vim.health.warn('Missing ' .. executable)
    end
  end
  vim.health.info 'Oxfmt and Oxlint are project-local. Install them with bun add -D oxfmt oxlint in projects that use Oxc.'
  vim.health.info 'Run :checkhealth vim.lsp, :ConformInfo, and :Mason to inspect language tooling.'
end

return M
