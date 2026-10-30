return {
  {
    'saghen/blink.cmp',
    version = '1.*',
    event = 'InsertEnter',
    opts = {
      keymap = {
        preset = 'default',
        ['<C-l>'] = { 'snippet_forward', 'fallback' },
        ['<C-h>'] = { 'snippet_backward', 'fallback' },
      },
      snippets = { preset = 'default' },
      sources = {
        default = { 'lazydev', 'lsp', 'path', 'snippets', 'buffer' },
        providers = {
          lazydev = {
            name = 'LazyDev',
            module = 'lazydev.integrations.blink',
            score_offset = 100,
          },
        },
      },
      completion = {
        documentation = { auto_show = true, auto_show_delay_ms = 300 },
        accept = { auto_brackets = { enabled = true } },
      },
      -- No native build or binary download is needed for completion.
      fuzzy = { implementation = 'lua' },
      signature = { enabled = true },
    },
  },
  {
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    opts = {},
  },
}
