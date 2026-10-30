return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main',
    lazy = false,
    build = ':TSUpdate',
    opts = {
      parsers = {
        'bash',
        'c',
        'css',
        'diff',
        'html',
        'javascript',
        'json',
        'lua',
        'luadoc',
        'markdown',
        'markdown_inline',
        'query',
        'rust',
        'toml',
        'tsx',
        'typescript',
        'vim',
        'vimdoc',
        'yaml',
        'zig',
      },
    },
    config = function(_, opts)
      local ts = require 'nvim-treesitter'
      ts.install(opts.parsers)
      local available = ts.get_available()

      local function attach(buf, language)
        if not vim.api.nvim_buf_is_valid(buf) or vim.treesitter.language.get_lang(vim.bo[buf].filetype) ~= language then
          return
        end
        if not vim.treesitter.language.add(language) then
          return
        end
        vim.treesitter.start(buf, language)
        vim.api.nvim_buf_call(buf, function()
          vim.wo.foldmethod = 'expr'
          vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
        end)
        if vim.treesitter.query.get(language, 'indents') then
          vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end

      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('treesitter', { clear = true }),
        callback = function(event)
          if vim.bo[event.buf].buftype ~= '' then
            return
          end
          local language = vim.treesitter.language.get_lang(event.match)
          if not language then
            return
          end
          if vim.tbl_contains(ts.get_installed 'parsers', language) then
            attach(event.buf, language)
          elseif vim.tbl_contains(available, language) then
            ts.install(language):await(function()
              attach(event.buf, language)
            end)
          end
        end,
      })
    end,
  },
}
