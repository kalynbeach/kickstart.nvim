return {
  {
    'stevearc/conform.nvim',
    event = 'BufWritePre',
    cmd = 'ConformInfo',
    keys = {
      {
        '<leader>f',
        function()
          require('conform').format { async = true }
        end,
        mode = { 'n', 'x' },
        desc = 'Format buffer or selection',
      },
    },
    opts = {
      notify_on_error = true,
      notify_no_formatters = true,
      -- Web formatting never falls back to another server when Oxfmt is missing.
      default_format_opts = { lsp_format = 'never' },
      format_on_save = { timeout_ms = 1000 },
      formatters_by_ft = {
        lua = { 'stylua' },
        rust = { lsp_format = 'fallback' },
        zig = { lsp_format = 'fallback' },
        javascript = { 'oxfmt' },
        javascriptreact = { 'oxfmt' },
        typescript = { 'oxfmt' },
        typescriptreact = { 'oxfmt' },
        json = { 'oxfmt' },
        jsonc = { 'oxfmt' },
        json5 = { 'oxfmt' },
        css = { 'oxfmt' },
        scss = { 'oxfmt' },
        less = { 'oxfmt' },
        html = { 'oxfmt' },
        vue = { 'oxfmt' },
        svelte = { 'oxfmt' },
        yaml = { 'oxfmt' },
        toml = { 'oxfmt' },
        markdown = { 'oxfmt' },
        ['markdown.mdx'] = { 'oxfmt' },
        graphql = { 'oxfmt' },
      },
      formatters = {
        oxfmt = {
          command = function(_, ctx)
            return require('config.project').binary(ctx.dirname, 'oxfmt') or '/nonexistent/oxfmt'
          end,
        },
      },
    },
  },
}
