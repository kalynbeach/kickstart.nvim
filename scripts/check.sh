#!/usr/bin/env bash
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
root="$(mktemp -d "${TMPDIR:-/tmp}/nvim-check.XXXXXX")"
cleanup() {
  if command -v trash >/dev/null 2>&1; then
    trash "$root"
  else
    rm -r -- "$root"
  fi
}
trap cleanup EXIT

export NVIM_APPNAME=nvim-check
export XDG_CONFIG_HOME="$root/config"
export XDG_DATA_HOME="$root/data"
export XDG_STATE_HOME="$root/state"
export XDG_CACHE_HOME="$root/cache"
export NVIM_TEST_CONFIG="$XDG_CONFIG_HOME/$NVIM_APPNAME"
export NVIM_TEST_PROJECT="$root/project"
mkdir -p "$NVIM_TEST_CONFIG" "$XDG_DATA_HOME/$NVIM_APPNAME"
cp "$repo/init.lua" "$repo/lazy-lock.json" "$repo/.stylua.toml" "$NVIM_TEST_CONFIG/"
cp -R "$repo/lua" "$repo/tests" "$NVIM_TEST_CONFIG/"
cp -R "$repo/tests/fixtures/web" "$NVIM_TEST_PROJECT"

bun install --cwd "$NVIM_TEST_PROJECT" --frozen-lockfile
for test in prepare smoke integration; do
  nvim --headless -i NONE -n \
    --cmd 'lua dofile(vim.env.NVIM_TEST_CONFIG .. "/tests/capture.lua")' \
    -c "lua vim.schedule(function() dofile(vim.env.NVIM_TEST_CONFIG .. '/tests/$test.lua') end)"
done
"$XDG_DATA_HOME/$NVIM_APPNAME/mason/bin/stylua" --check "$repo"
