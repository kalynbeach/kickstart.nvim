return {
  {
    'nvim-telescope/telescope.nvim',
    version = '0.2.*',
    cmd = 'Telescope',
    dependencies = {
      'nvim-lua/plenary.nvim',
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'make',
        cond = function()
          return vim.fn.executable 'make' == 1
        end,
      },
      'nvim-telescope/telescope-ui-select.nvim',
      'nvim-tree/nvim-web-devicons',
    },
    keys = {
      { '<leader>sh', '<cmd>Telescope help_tags<CR>', desc = 'Search help' },
      { '<leader>sk', '<cmd>Telescope keymaps<CR>', desc = 'Search keymaps' },
      { '<leader>sf', '<cmd>Telescope find_files<CR>', desc = 'Search files' },
      { '<leader>ss', '<cmd>Telescope builtin<CR>', desc = 'Search pickers' },
      { '<leader>sw', '<cmd>Telescope grep_string<CR>', desc = 'Search current word' },
      { '<leader>sg', '<cmd>Telescope live_grep<CR>', desc = 'Search by grep' },
      { '<leader>sd', '<cmd>Telescope diagnostics<CR>', desc = 'Search diagnostics' },
      { '<leader>sr', '<cmd>Telescope resume<CR>', desc = 'Resume search' },
      { '<leader>s.', '<cmd>Telescope oldfiles<CR>', desc = 'Search recent files' },
      { '<leader><leader>', '<cmd>Telescope buffers<CR>', desc = 'Find buffers' },
      {
        '<leader>/',
        function()
          require('telescope.builtin').current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
            winblend = 10,
            previewer = false,
          })
        end,
        desc = 'Search current buffer',
      },
      {
        '<leader>s/',
        function()
          require('telescope.builtin').live_grep { grep_open_files = true, prompt_title = 'Live Grep in Open Files' }
        end,
        desc = 'Search open files',
      },
      {
        '<leader>sn',
        function()
          require('telescope.builtin').find_files { cwd = vim.fn.stdpath 'config' }
        end,
        desc = 'Search Neovim files',
      },
    },
    config = function()
      local telescope = require 'telescope'
      telescope.setup {
        pickers = { find_files = { hidden = true } },
        defaults = { file_ignore_patterns = { '^%.git/' } },
        extensions = { ['ui-select'] = { require('telescope.themes').get_dropdown() } },
      }
      if vim.fn.executable 'make' == 1 then
        telescope.load_extension 'fzf'
      end
      telescope.load_extension 'ui-select'
    end,
  },
  {
    'nvim-neo-tree/neo-tree.nvim',
    version = '*',
    dependencies = { 'nvim-lua/plenary.nvim', 'nvim-tree/nvim-web-devicons', 'MunifTanjim/nui.nvim' },
    cmd = 'Neotree',
    keys = {
      { '\\', '<cmd>Neotree reveal<CR>', desc = 'Reveal file in Neo-tree', silent = true },
    },
    opts = {
      filesystem = { window = { mappings = { ['\\'] = 'close_window' } } },
    },
  },
}
