vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic list' })
vim.keymap.set('n', '<leader>td', function()
  local enabled = vim.diagnostic.config().virtual_lines
  vim.diagnostic.config { virtual_lines = not enabled and { current_line = true } or false }
end, { desc = 'Toggle diagnostic lines' })
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

for key, direction in pairs { h = 'left', j = 'lower', k = 'upper', l = 'right' } do
  vim.keymap.set('n', '<C-' .. key .. '>', '<C-w><C-' .. key .. '>', { desc = 'Move to ' .. direction .. ' window' })
end
