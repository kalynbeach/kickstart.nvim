local ok, err = xpcall(function()
  local project = assert(vim.uv.fs_realpath(vim.env.NVIM_TEST_PROJECT))
  local function wait(predicate, message)
    assert(vim.wait(20000, predicate), message)
  end
  local function client(buf, name)
    return vim.lsp.get_clients({ bufnr = buf, name = name })[1]
  end
  local function text(buf)
    return table.concat(vim.api.nvim_buf_get_lines(buf or 0, 0, -1, false), '\n')
  end

  vim.fn.mkdir(project .. '/.git', 'p')
  local file = project .. '/example.ts'
  vim.fn.writefile({
    'export const escaped = "\\a";',
    'export const broken: number = "wrong";',
    'debugger;',
    'export const model={answer:1};',
    'model.an',
  }, file)
  -- Use the fixture's TS server rather than any existing Mason installation.
  require('lazy').load { plugins = { 'nvim-lspconfig' } }
  vim.lsp.config('ts_ls', { cmd = { project .. '/node_modules/.bin/typescript-language-server', '--stdio' } })
  vim.lsp.enable 'ts_ls'
  vim.cmd.edit(file)
  local buf = vim.api.nvim_get_current_buf()
  wait(function()
    return client(buf, 'ts_ls') and client(buf, 'oxlint')
  end, 'TypeScript and Oxlint did not both attach')
  wait(function()
    local type_error, lint_error = false, false
    for _, diagnostic in ipairs(vim.diagnostic.get(buf)) do
      type_error = type_error or diagnostic.code == 2322
      lint_error = lint_error or diagnostic.message:find('Unnecessary escape', 1, true) ~= nil
    end
    return type_error and lint_error
  end, 'Expected TypeScript type error and Oxlint diagnostic')
  assert(text(buf):find('\\a', 1, true), 'Lint fixes ran without an explicit action')
  assert(not client(buf, 'eslint'), 'ESLint attached alongside Oxlint')

  -- The user's save action must use the local Oxfmt configuration.
  vim.cmd.write()
  assert(vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == "export const escaped = '\\a'", 'Oxfmt did not honor project quotes and semicolons')
  assert(vim.fn.readfile(file)[4] == 'export const model = { answer: 1 }', 'Format-on-save did not write formatted output')
  vim.cmd 'LspOxlintFixAll'
  wait(function()
    return not text(buf):find('\\a', 1, true)
  end, 'Explicit Oxlint fix-all did not apply a safe fix')

  vim.api.nvim_win_set_cursor(0, { 2, 14 })
  vim.lsp.buf.rename 'renamed'
  wait(function()
    return vim.api.nvim_buf_get_lines(buf, 1, 2, false)[1]:find('renamed', 1, true) ~= nil
  end, 'TypeScript rename did not update the buffer')

  -- Buffer-local hint toggles must not affect another attached buffer.
  local other_file = project .. '/other.ts'
  vim.fn.writefile({ 'export const other = 1' }, other_file)
  vim.cmd.edit(other_file)
  local other = vim.api.nvim_get_current_buf()
  wait(function()
    return client(other, 'ts_ls') ~= nil
  end, 'TypeScript did not attach to the second buffer')
  vim.api.nvim_set_current_buf(buf)
  local hint_toggle = vim.fn.maparg('<leader>th', 'n', false, true).callback
  assert(hint_toggle, 'TypeScript inlay hint mapping is missing')
  local initial = vim.lsp.inlay_hint.is_enabled { bufnr = buf }
  local other_initial = vim.lsp.inlay_hint.is_enabled { bufnr = other }
  hint_toggle()
  assert(vim.lsp.inlay_hint.is_enabled { bufnr = buf } ~= initial)
  assert(vim.lsp.inlay_hint.is_enabled { bufnr = other } == other_initial, 'Hint toggle changed another buffer')
  hint_toggle()
  vim.cmd.write()

  -- Nested package configs must find hoisted tools and retain separate LSP roots.
  for _, package in ipairs { 'one', 'two' } do
    local root = project .. '/packages/' .. package
    vim.fn.mkdir(root .. '/src', 'p')
    vim.fn.writefile({ '{}' }, root .. '/.oxlintrc.json')
    vim.fn.writefile({ 'export const value = 1' }, root .. '/src/index.ts')
    vim.cmd.edit(root .. '/src/index.ts')
    local nested = vim.api.nvim_get_current_buf()
    wait(function()
      return client(nested, 'oxlint') ~= nil
    end, 'Oxlint did not find the hoisted binary for ' .. package)
    assert(client(nested, 'oxlint').root_dir == root, 'Oxlint reused a different package config root')
  end

  -- An ancestor config can also use a binary installed only in a child package.
  local inverse = vim.fs.dirname(project) .. '/inverse'
  local local_package = inverse .. '/packages/app'
  vim.fn.mkdir(inverse .. '/.git', 'p')
  vim.fn.mkdir(local_package .. '/src', 'p')
  vim.fn.writefile({ '{"rules":{"no-console":"error"}}' }, inverse .. '/.oxlintrc.json')
  vim.fn.writefile({ '{}' }, local_package .. '/package.json')
  assert(vim.uv.fs_symlink(project .. '/node_modules', local_package .. '/node_modules'))
  vim.fn.writefile({ 'console.log("test")' }, local_package .. '/src/index.ts')
  vim.cmd.edit(local_package .. '/src/index.ts')
  local local_buf = vim.api.nvim_get_current_buf()
  wait(function()
    return client(local_buf, 'oxlint') ~= nil
  end, 'Oxlint missed a package-local binary with an ancestor config')
  assert(client(local_buf, 'oxlint').root_dir == local_package, 'Oxlint did not retain the local tool root')
  wait(function()
    for _, diagnostic in ipairs(vim.diagnostic.get(local_buf)) do
      if diagnostic.message:find('console', 1, true) and diagnostic.severity == vim.diagnostic.severity.ERROR then
        return true
      end
    end
    return false
  end, 'Oxlint did not honor the ancestor config')

  -- Show and accept an actual LSP result through Blink's public interface.
  vim.api.nvim_set_current_buf(buf)
  vim.api.nvim_win_set_cursor(0, { 5, #'model.an' - 1 })
  local completion_ok, completion_error
  -- Run inside the insert-mode input loop, then send Escape so feedkeys can return.
  vim.defer_fn(function()
    completion_ok, completion_error = xpcall(function()
      local cmp = require 'blink.cmp'
      cmp.show { providers = { 'lsp' } }
      local index
      wait(function()
        for i, item in ipairs(cmp.get_items()) do
          if item.label == 'answer' then
            index = i
            return cmp.is_menu_visible()
          end
        end
        return false
      end, 'Blink did not display the TypeScript completion')
      cmp.accept { index = index }
      wait(function()
        return vim.api.nvim_buf_get_lines(buf, 4, 5, false)[1] == 'model.answer'
      end, 'Blink did not accept the completion')
    end, debug.traceback)
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, false, true), 't', false)
  end, 50)
  vim.api.nvim_feedkeys('A', 'xt!', false)
  assert(completion_ok, completion_error)

  assert(#test_errors == 0, table.concat(test_errors, '\n'))
  assert(vim.v.errmsg == '', vim.v.errmsg)
  print 'Oxfmt save, Oxlint diagnostics/fixes, TypeScript rename, hint scope, monorepo roots, and Blink completion: OK'
end, debug.traceback)
if not ok then
  print(err)
  vim.cmd 'cquit 1'
end
vim.cmd 'qa!'
