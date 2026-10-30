local M = {}

-- Keep tool discovery inside the repository or standalone package, never the home directory.
function M.root(path)
  return vim.fs.root(path, '.git') or vim.fs.root(path, { 'bun.lock', 'bun.lockb' }) or vim.fs.root(path, 'package.json')
end

local function ancestors(path)
  local root = M.root(path)
  local dirs = {}
  if not root then
    return dirs
  end
  local dir = vim.fs.normalize(path)
  while true do
    dirs[#dirs + 1] = dir
    if dir == root then
      break
    end
    local parent = vim.fs.dirname(dir)
    if not parent or parent == dir then
      break
    end
    dir = parent
  end
  return dirs
end

function M.binary(path, name)
  for _, dir in ipairs(ancestors(path)) do
    local binary = vim.fs.joinpath(dir, 'node_modules', '.bin', name)
    if vim.fn.executable(binary) == 1 then
      return binary, dir
    end
  end
end

function M.config_root(path, names)
  for _, dir in ipairs(ancestors(path)) do
    for _, name in ipairs(names) do
      if vim.uv.fs_stat(vim.fs.joinpath(dir, name)) then
        return dir
      end
    end
  end
end

return M
