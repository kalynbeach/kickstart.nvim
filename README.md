# Neovim

Personal Neovim configuration, derived from Kickstart. Requires Neovim 0.12 or newer.

## Dependencies

- Git, a C compiler, Make, curl, tar, unzip, and ripgrep.
- Tree-sitter CLI 0.26.1 or newer. The Homebrew formula is `tree-sitter-cli`, not the `tree-sitter` library.
- A Nerd Font selected in the terminal.
- Bun for project-local Oxc tools and the checks.
- Node.js for language servers whose executables require it.

macOS dependencies:

```sh
brew install neovim ripgrep tree-sitter-cli
```

Lazy installs plugins on first startup. Mason installs Lua, TypeScript, Tailwind CSS, CSS, Rust, and Zig language servers during an interactive session, plus StyLua.
Headless checks install their own required tools.

## Files

```text
init.lua                 Loads options, mappings, autocommands, and Lazy
lua/config/              Editor settings, project tool discovery, and health checks
lua/plugins/             Plugin specifications grouped by responsibility
lazy-lock.json           Exact plugin revisions
scripts/check.sh         Isolated runtime and formatting checks
tests/                   Headless checks and a locked Oxc fixture
```

## Language tooling

| Responsibility | Tool |
| --- | --- |
| Completion and native snippets | Blink 1.x |
| Lua configuration completion | LuaLS and Lazydev |
| TypeScript completion, navigation, and type errors | TypeScript language server |
| Web formatting | Project-local Oxfmt through Conform |
| Web lint diagnostics and explicit fixes | Project-local Oxlint language server |
| Lua formatting | StyLua through Conform |
| Rust and Zig formatting | Their language servers |
| Highlighting, folds, and indentation | Treesitter `main` |

### Oxc projects

Project dependencies:

```sh
bun add -D oxfmt oxlint
```

Oxfmt runs on save and through `<leader>f` for JS, JSX, TS, TSX, JSON, JSONC, JSON5, CSS, SCSS, Less, HTML, Vue, Svelte, YAML, TOML, Markdown, MDX, and GraphQL.
Support for each format depends on the project's installed Oxfmt version.
Its configuration files include `.oxfmtrc.json`, `.oxfmtrc.jsonc`, and `oxfmt.config.ts`.

Oxlint attaches only when the repository or package has both a local executable and an explicit `.oxlintrc.json`, `.oxlintrc.jsonc`, or `oxlint.config.ts`.
Both tools can use binaries hoisted to an ancestor inside the repository.
Outside Git, discovery stops at the Bun workspace or package root.
Global binaries are not substitutes for missing project dependencies.

Oxlint fixes run only through `<leader>cf` or `:LspOxlintFixAll`.
They use safe fixes and do not run automatically on save.
ESLint is not enabled automatically.
Prettier is not configured, and missing Oxfmt never falls back to an LSP formatter.

## Mappings

The leader key is Space.

| Mapping | Action |
| --- | --- |
| `<leader>sf` | Find files, including hidden files outside Git's ignore rules |
| `<leader>sg` | Search file contents |
| `<leader><leader>` | Find buffers |
| `<leader>sh`, `<leader>sk` | Search help and mappings |
| `<leader>sn` | Find Neovim configuration files |
| `\\` | Reveal the current file in Neo-tree |
| `gd`, `gD` | Definition and declaration |
| `grr`, `gri`, `grt` | References, implementations, and type definitions |
| `grn`, `gra` | Rename and code actions |
| `gO`, `<leader>ws` | Document and workspace symbols |
| `<leader>f` | Format the buffer or selection |
| `<leader>cf` | Apply safe Oxlint fixes |
| `<leader>td` | Toggle current-line diagnostic text |
| `<leader>th` | Toggle inlay hints in the current buffer |
| `<leader>q` | Open the diagnostic list |
| `[d`, `]d` | Previous and next diagnostic |
| `[c`, `]c` | Previous and next Git hunk |
| `<leader>hs`, `<leader>hr` | Stage and reset a hunk |
| `<leader>hp`, `<leader>hP` | Floating and inline hunk previews |
| `<C-y>` | Accept a completion |
| `<C-n>`, `<C-p>` | Select the next and previous completion |
| `<Tab>`, `<S-Tab>` | Move between snippet placeholders |
| `<C-l>`, `<C-h>` in insert mode | Alternate snippet jumps |
| `<C-h/j/k/l>` in normal mode | Move between windows |
| `<Esc><Esc>` in terminal mode | Return to normal mode |

The existing `<leader>rn`, `<leader>ca`, `<leader>ds`, `<leader>D`, and `gI` mappings remain available.
The old `gr` mapping is replaced by `grr` so it does not delay the native `gr*` mappings.
Blink uses its Lua matcher, so it needs no native build or binary download.

## Maintenance

- `:Lazy update` updates plugins and `lazy-lock.json`.
- `:Lazy restore` restores the revisions in the lockfile.
- `:TSUpdate` updates parsers to match the installed Treesitter revision.
- `:Mason` shows installed language tools.
- `:ConformInfo` shows the formatter selected for the current buffer.
- `:checkhealth config` checks this configuration's dependencies.
- `:checkhealth vim.lsp` shows active and enabled language servers.

The lockfile belongs in version control with configuration changes.

## Checks

```sh
scripts/check.sh
```

The script copies the configuration into temporary XDG directories.
It restores locked plugins, installs test tools, and runs startup and interaction checks.
The web fixture verifies Oxfmt-on-save, Oxlint diagnostics and explicit fixes, TypeScript rename, buffer-local hints, hoisted tools, and Blink completion.
It also checks missing-tool behavior, navigation, snippets, delimiter pairing, parser loading, and Lua formatting.
No test uses the normal Neovim data or state directories.

