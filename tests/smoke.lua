local ok, err = xpcall(function()
  local config = assert(vim.uv.fs_realpath(vim.env.NVIM_TEST_CONFIG))
  local project = assert(vim.uv.fs_realpath(vim.env.NVIM_TEST_PROJECT))
  for _, file in ipairs(vim.fn.glob(config .. '/lua/**/*.lua', false, true)) do
    assert(loadfile(file))
  end
  assert(loadfile(config .. '/init.lua'))

  vim.cmd 'Mason'
  assert(vim.api.nvim_get_commands({}).Mason, 'Mason is unavailable without an open file')
  assert(
    vim.wait(5000, function()
      return vim.bo.filetype == 'mason' and vim.fn.maparg('q', 'n') ~= ''
    end),
    'Mason did not open its window'
  )
  vim.api.nvim_feedkeys('q', 'xt', false)
  assert(
    vim.wait(5000, function()
      return #vim.api.nvim_list_wins() == 1
    end),
    'Mason did not close'
  )
  assert(vim.g.colors_name == 'lackluster-mint', 'Colorscheme did not load')
  assert(vim.o.statusline ~= '' and not vim.o.statusline:find 'MiniStatusline', 'Expected one Lualine statusline')
  local toggle = vim.fn.maparg('<leader>td', 'n', false, true).callback
  toggle()
  assert(vim.diagnostic.config().virtual_lines == false)
  toggle()
  assert(vim.diagnostic.config().virtual_lines.current_line)

  vim.cmd 'enew!'
  require('lazy').load { plugins = { 'nvim-autopairs' } }
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>i(<Esc>', true, false, true), 'xt', false)
  assert(vim.api.nvim_get_current_line() == '()', 'Typed delimiter pairing produced ' .. vim.inspect(vim.api.nvim_get_current_line()))
  vim.cmd 'enew!'

  for language, source in pairs {
    lua = 'local value = 1',
    typescript = 'const value: number = 1',
    tsx = 'const Component = () => <div />',
    json = '{"value": 1}',
    markdown = '# Heading',
  } do
    local parser = vim.treesitter.get_string_parser(source, language)
    assert(#parser:parse() > 0, language .. ' parser failed')
    assert(vim.treesitter.query.get(language, 'highlights'), language .. ' highlight queries missing')
  end

  vim.cmd.edit(config .. '/init.lua')
  local lua_buf = vim.api.nvim_get_current_buf()
  assert(
    vim.wait(20000, function()
      return #vim.lsp.get_clients { bufnr = lua_buf, name = 'lua_ls' } == 1
    end),
    'Lua language server did not attach'
  )
  assert(vim.treesitter.highlighter.active[lua_buf], 'FileType did not enable highlighting')
  assert(vim.wo.foldmethod == 'expr', 'Treesitter folds are not enabled')
  assert(vim.fn.maparg('grn', 'n', false, true).buffer == 1, 'LSP mappings are missing')
  assert(require('lazydev.config').enabled(lua_buf), 'Lazydev is not enabled')

  -- Select a file through a real picker, including its compiled fzf sorter.
  require('telescope.builtin').find_files { cwd = config, default_text = 'init.lua' }
  local prompt = vim.api.nvim_get_current_buf()
  assert(
    vim.wait(5000, function()
      local entry = require('telescope.actions.state').get_selected_entry()
      return entry and (entry.path == config .. '/init.lua' or entry.value == 'init.lua')
    end),
    'Telescope did not return files'
  )
  require('telescope.actions').select_default(prompt)
  assert(
    vim.wait(3000, function()
      return vim.api.nvim_buf_get_name(0) == config .. '/init.lua'
    end),
    'Telescope selection opened ' .. vim.api.nvim_buf_get_name(0) .. ' instead of init.lua'
  )
  require('telescope.builtin').grep_string { cwd = config, search = 'require' }
  local grep_prompt = vim.api.nvim_get_current_buf()
  assert(
    vim.wait(5000, function()
      local entry = require('telescope.actions.state').get_selected_entry()
      return entry and entry.text and entry.text:find('require', 1, true)
    end),
    'Telescope did not return ripgrep matches'
  )
  require('telescope.actions').close(grep_prompt)
  vim.cmd('Neotree reveal dir=' .. vim.fn.fnameescape(config))
  assert(
    vim.wait(5000, function()
      for _, win in ipairs(vim.api.nvim_list_wins()) do
        local buf = vim.api.nvim_win_get_buf(win)
        if vim.bo[buf].filetype == 'neo-tree' and table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), '\n'):find('init.lua', 1, true) then
          return true
        end
      end
      return false
    end),
    'Neo-tree did not render the config directory'
  )
  vim.cmd 'Neotree close'

  -- A package-local config may use tools hoisted to the repository root.
  local tools = require 'config.project'
  vim.fn.mkdir(project .. '/.git', 'p')
  local nested = project .. '/packages/example/src'
  vim.fn.mkdir(nested, 'p')
  vim.fn.writefile({ '{}' }, project .. '/packages/example/.oxlintrc.json')
  assert(tools.binary(nested, 'oxfmt') == project .. '/node_modules/.bin/oxfmt')
  assert(tools.config_root(nested, { '.oxlintrc.json' }) == project .. '/packages/example')

  -- A project without its own binary must not use one from PATH or an LSP formatter.
  local missing = vim.fs.dirname(project) .. '/missing-tools'
  vim.fn.mkdir(missing .. '/.git', 'p')
  vim.fn.writefile({ '{}' }, missing .. '/package.json')
  vim.fn.writefile({ '{}' }, missing .. '/.oxlintrc.json')
  vim.fn.writefile({ 'const value={a:1};' }, missing .. '/example.ts')
  vim.env.PATH = project .. '/node_modules/.bin:' .. vim.env.PATH
  vim.lsp.config('ts_ls', { cmd = { project .. '/node_modules/.bin/typescript-language-server', '--stdio' } })
  vim.lsp.enable 'ts_ls'
  vim.cmd.edit(missing .. '/example.ts')
  local before = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  assert(tools.binary(missing, 'oxfmt') == nil, 'Tool discovery escaped the repository')
  local conform = require 'conform'
  assert(not conform.get_formatter_info('oxfmt').available, 'Global Oxfmt should not be selected')
  conform.format { async = false, quiet = true }
  assert(vim.deep_equal(before, vim.api.nvim_buf_get_lines(0, 0, -1, false)), 'Missing Oxfmt changed the buffer')
  assert(vim.wait(15000, function()
    return #vim.lsp.get_clients { bufnr = 0, name = 'ts_ls' } > 0
  end))
  assert(#vim.lsp.get_clients { bufnr = 0, name = 'oxlint' } == 0, 'Oxlint attached without a local binary')
  assert(#vim.lsp.get_clients { name = 'eslint' } == 0, 'ESLint was enabled implicitly')

  local unconfigured = vim.fs.dirname(project) .. '/unconfigured'
  vim.fn.mkdir(unconfigured .. '/.git', 'p')
  vim.fn.writefile({ '{}' }, unconfigured .. '/package.json')
  assert(vim.uv.fs_symlink(project .. '/node_modules', unconfigured .. '/node_modules'))
  vim.fn.writefile({ 'export const value = 1' }, unconfigured .. '/example.ts')
  vim.cmd.edit(unconfigured .. '/example.ts')
  assert(
    vim.wait(15000, function()
      return #vim.lsp.get_clients { bufnr = 0, name = 'ts_ls' } > 0
    end),
    'TypeScript did not attach to the unconfigured project'
  )
  assert(#vim.lsp.get_clients { bufnr = 0, name = 'oxlint' } == 0, 'Oxlint attached without a project config')

  vim.fn.writefile({ '#    Heading', '', '{1+2}' }, project .. '/example.mdx')
  vim.cmd.edit(project .. '/example.mdx')
  assert(vim.bo.filetype == 'markdown.mdx', 'MDX filetype detection failed')
  conform.format { async = false }
  assert(vim.api.nvim_buf_get_lines(0, 0, 1, false)[1] == '# Heading', 'MDX did not use Oxfmt')
  vim.cmd 'enew!'

  vim.fn.writefile({ 'local value={a=1}' }, project .. '/example.lua')
  vim.cmd.edit(project .. '/example.lua')
  conform.format { async = false }
  assert(vim.api.nvim_get_current_line() == 'local value = { a = 1 }', 'Conform did not run StyLua')
  vim.cmd 'enew!'
  vim.snippet.expand 'hello ${1:world} ${2:again}$0'
  assert(vim.api.nvim_get_current_line() == 'hello world again')
  assert(vim.snippet.active { direction = 1 }, 'Native snippet forward jump is unavailable')
  vim.snippet.jump(1)
  assert(vim.snippet.active { direction = -1 }, 'Native snippet backward jump is unavailable')
  vim.snippet.jump(-1)
  vim.snippet.stop()
  assert(#test_errors == 0, table.concat(test_errors, '\n'))
  assert(vim.v.errmsg == '', vim.v.errmsg)
  print 'Startup, navigation, snippets, pairing, parsers, and missing-tool behavior: OK'
end, debug.traceback)
if not ok then
  print(err)
  vim.cmd 'cquit 1'
end
vim.cmd 'qa!'
