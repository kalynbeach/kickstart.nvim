return {
  {
    'folke/lazydev.nvim',
    ft = 'lua',
    opts = {
      library = {
        { path = '${3rd}/luv/library', words = { 'vim%.uv' } },
      },
    },
  },
  {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = {
      { 'mason-org/mason.nvim', cmd = 'Mason', opts = {} },
      'mason-org/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      { 'j-hui/fidget.nvim', opts = {} },
      'saghen/blink.cmp',
    },
    config = function()
      local servers = {
        lua_ls = { settings = { Lua = { completion = { callSnippet = 'Replace' } } } },
        ts_ls = {},
        tailwindcss = {},
        cssls = {},
        rust_analyzer = {},
        zls = {},
      }

      vim.lsp.config('*', { capabilities = require('blink.cmp').get_lsp_capabilities() })
      for name, config in pairs(servers) do
        vim.lsp.config(name, config)
      end

      require('mason-lspconfig').setup {
        ensure_installed = vim.tbl_keys(servers),
        -- Only declared servers activate, and only after Mason has installed them.
        automatic_enable = vim.tbl_keys(servers),
      }
      require('mason-tool-installer').setup {
        ensure_installed = { 'stylua' },
        run_on_start = #vim.api.nvim_list_uis() > 0,
      }

      -- Oxc belongs to the project. An installed global/Mason binary is not an opt-in.
      local project = require 'config.project'
      vim.lsp.config('oxlint', {
        workspace_required = true,
        root_dir = function(bufnr, on_dir)
          local path = vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr))
          local root = project.config_root(path, { '.oxlintrc.json', '.oxlintrc.jsonc', 'oxlint.config.ts' })
          local binary, tool_root = project.binary(path, 'oxlint')
          if root and binary then
            -- The deeper ancestor distinguishes both nested configs and package-local tool versions.
            on_dir(#root >= #tool_root and root or tool_root)
          end
        end,
        cmd = function(dispatchers, config)
          local binary = assert(project.binary(config.root_dir, 'oxlint'), 'Project-local oxlint is no longer available')
          return vim.lsp.rpc.start({ binary, '--lsp' }, dispatchers)
        end,
        settings = { fixKind = 'safe_fix' },
      })
      vim.lsp.enable 'oxlint'

      local group = vim.api.nvim_create_augroup('lsp', { clear = true })
      vim.api.nvim_create_autocmd('LspAttach', {
        group = group,
        callback = function(event)
          local function map(keys, fn, desc, mode)
            vim.keymap.set(mode or 'n', keys, fn, { buffer = event.buf, desc = desc })
          end
          local telescope = require 'telescope.builtin'
          map('gd', telescope.lsp_definitions, 'Go to definition')
          map('grr', telescope.lsp_references, 'Find references')
          map('gri', telescope.lsp_implementations, 'Go to implementation')
          map('grt', telescope.lsp_type_definitions, 'Go to type definition')
          map('gO', telescope.lsp_document_symbols, 'Document symbols')
          map('grn', vim.lsp.buf.rename, 'Rename symbol')
          map('gra', vim.lsp.buf.code_action, 'Code action', { 'n', 'x' })
          map('gD', vim.lsp.buf.declaration, 'Go to declaration')
          -- Keep familiar leader mappings alongside the native gr* conventions.
          map('gI', telescope.lsp_implementations, 'Go to implementation')
          map('<leader>D', telescope.lsp_type_definitions, 'Type definition')
          map('<leader>ds', telescope.lsp_document_symbols, 'Document symbols')
          map('<leader>ws', telescope.lsp_dynamic_workspace_symbols, 'Workspace symbols')
          map('<leader>rn', vim.lsp.buf.rename, 'Rename symbol')
          map('<leader>ca', vim.lsp.buf.code_action, 'Code action', { 'n', 'x' })

          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client:supports_method('textDocument/inlayHint', event.buf) then
            map('<leader>th', function()
              local filter = { bufnr = event.buf }
              vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled(filter), filter)
            end, 'Toggle inlay hints')
          end
          if client and client.name == 'oxlint' then
            map('<leader>cf', '<cmd>LspOxlintFixAll<CR>', 'Apply safe Oxlint fixes')
          end
        end,
      })

      -- One set of callbacks works even when several servers attach to a buffer.
      vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
        group = group,
        callback = function(event)
          if #vim.lsp.get_clients { bufnr = event.buf, method = 'textDocument/documentHighlight' } > 0 then
            vim.lsp.buf.document_highlight()
          end
        end,
      })
      vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI', 'LspDetach' }, {
        group = group,
        callback = function(event)
          if vim.api.nvim_buf_is_valid(event.buf) then
            vim.api.nvim_buf_call(event.buf, vim.lsp.buf.clear_references)
          end
        end,
      })
    end,
  },
}
