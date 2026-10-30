return {
  {
    'slugbyte/lackluster.nvim',
    priority = 1000,
    config = function()
      local lackluster = require 'lackluster'
      lackluster.setup {
        tweak_background = {
          normal = lackluster.color.gray1,
          menu = '#101010',
          telescope = '#101010',
          popup = '#101010',
        },
        tweak_syntax = {
          comment = lackluster.color.gray4,
          keyword = lackluster.color.blue,
          keyword_return = lackluster.color.blue,
          keyword_exception = lackluster.color.blue,
          string = lackluster.color.green,
        },
      }
      vim.cmd.colorscheme 'lackluster-mint'
      vim.cmd.hi 'Comment gui=none'
    end,
  },
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    opts = { options = { theme = 'lackluster' } },
  },
  {
    'folke/which-key.nvim',
    event = 'VimEnter',
    opts = {
      delay = 0,
      spec = {
        { '<leader>c', group = 'Code', mode = { 'n', 'x' } },
        { '<leader>d', group = 'Document' },
        { '<leader>r', group = 'Rename' },
        { '<leader>s', group = 'Search' },
        { '<leader>w', group = 'Workspace' },
        { '<leader>t', group = 'Toggle' },
        { '<leader>h', group = 'Git hunk', mode = { 'n', 'x' } },
      },
    },
  },
  {
    'folke/todo-comments.nvim',
    event = 'VimEnter',
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = { signs = false },
  },
  {
    'nvim-mini/mini.nvim',
    config = function()
      require('mini.ai').setup { n_lines = 500 }
      require('mini.surround').setup()
    end,
  },
  'tpope/vim-sleuth',
}
