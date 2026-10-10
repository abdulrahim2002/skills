---
name: setup-vim-markdown-preview
description: Set up a live, custom-styled Markdown preview in Vim (not Neovim) that renders in the browser. Use when asked to add Markdown preview to a vimrc, style previm's output, or replicate a themed previm setup in another Vim configuration.
metadata:
  author: skills
  version: "1.0.0"
---

# Setup Vim Markdown Preview

Teach a Vim user's `.vimrc` to open a live Markdown preview in the default
browser, styled with a custom CSS theme instead of previm's plain default
stylesheet. This skill is Vim-specific (not Neovim) and assumes the
[Vundle](https://github.com/VundleVim/Vundle.vim) plugin manager; adapt the
plugin declarations if the target vimrc uses vim-plug or packer instead.

Light/dark switching is intentionally out of scope — it depends on
OS-specific theme-detection tooling. Ship one stylesheet (or two, selected
manually) and leave automatic switching as an optional extension (see below).

## How The Pieces Fit Together

1. **[previm](https://github.com/previm/previm)** — the core plugin. Watches
   the current Markdown buffer and renders it to a temporary HTML file,
   auto-refreshing the browser tab on save.
2. **[open-browser.vim](https://github.com/tyru/open-browser.vim)** — a hard
   dependency of previm; it's what actually opens the rendered HTML in the
   system's default browser.
3. **A custom CSS file** — previm ships a default stylesheet that renders as
   plain black-on-white HTML. Disabling it and pointing `g:previm_custom_css_path`
   at your own CSS gives full control over typography, code blocks, tables,
   blockquotes, etc.
4. **A keybinding** — `:PrevimOpen` is the command previm exposes; map it to
   something memorable like `<leader>mp`.

## Setup Steps

1. **Confirm a plugin manager is present.** This skill assumes Vundle is
   already bootstrapped (`call vundle#begin()` / `call vundle#end()` wrapping
   the `Plugin '...'` lines in `.vimrc`). If the target config uses vim-plug
   or packer, translate `Plugin 'author/repo'` to that manager's equivalent
   syntax (`Plug 'author/repo'`, etc.) — the plugin names and options stay
   the same.

2. **Add the two plugins** inside the Vundle block:

   ```vim
   Plugin 'previm/previm'                     " Markdown preview in browser
   Plugin 'tyru/open-browser.vim'             " Dependency for previm
   ```

3. **Install a custom CSS theme.** Create a directory under `~/.vim/bundle/`
   to hold it (previm doesn't manage this itself, so any path works, e.g.
   `~/.vim/bundle/previm-theme/`) and copy in a stylesheet. This skill
   inlines a Nord-palette dark theme and light theme as a starting point —
   see `files/nord-dark.css` and `files/nord-light.css`. Both style the same
   set of previm output elements:
   - `body` — base font stack, size, line-height, max content width
   - `h1`–`h6` — heading scale, weight, and the `h1`/`h2` bottom-border rule
   - `a` / `a:hover` — link color and hover underline
   - `code` / `pre` / `pre code` — inline code chips vs. fenced code blocks
   - `blockquote` — left-border accent + tinted background
   - `table` / `th` / `td` / `tr:nth-child(even)` / `tr:hover` — zebra-striped,
     bordered tables
   - `hr`, `img`, `ul`/`ol`/`li`, `strong`/`em` — minor polish
   - `input[type="checkbox"]` — GitHub-style task list checkboxes
   - `details`/`summary` — collapsible sections
   - `::selection`, `::-webkit-scrollbar*` — selection highlight + scrollbar
     styling for WebKit-based browsers
   - `#header` — the small metadata line previm renders above the document

   To build a theme from scratch instead, start from one of these files and
   swap the color variables; keep the selector list so every previm element
   stays styled.

4. **Wire previm to the custom CSS and disable the default stylesheet:**

   ```vim
   let g:previm_disable_default_css = 1
   let g:previm_custom_css_path = '~/.vim/bundle/previm-theme/nord-dark.css'
   ```

   `g:previm_custom_css_path` must be set (even to a hardcoded path) before
   `:PrevimOpen` first runs — plugin options set this way are safe to place
   anywhere after the `Plugin` declarations, but before the preview is opened.

5. **Add a keybinding** so the preview is one keystroke away:

   ```vim
   nnoremap <leader>mp :PrevimOpen<CR>
   ```

6. **Install the plugins and verify:**

   ```sh
   vim +PluginInstall +qall
   ```

   Open any `.md` file in Vim, run `:PrevimOpen` (or the mapped leader key),
   and confirm the browser opens the rendered Markdown using the custom
   theme — headings, code fences, tables, and links should all reflect the
   CSS above rather than black-on-white defaults.

The full ready-to-paste snippet is in `files/vimrc-snippet.vim`.

## Optional: Automatic Light/Dark Switching

The original setup this skill was extracted from also auto-selected between
a dark and light stylesheet based on the OS appearance, using a small
external binary (e.g. `darkmode-check` on macOS, comparable tools exist for
Linux/Windows) and a vimrc function like:

```vim
function! SetPrevimTheme()
  let l:output = system("~/.local/bin/darkmode-check")
  if l:output =~# 'dark'
    let g:previm_custom_css_path = '~/.vim/bundle/previm-theme/nord-dark.css'
  else
    let g:previm_custom_css_path = '~/.vim/bundle/previm-theme/nord-light.css'
  endif
endfunction

call SetPrevimTheme()
```

This is OS-dependent plumbing, not styling, so it's omitted from the core
setup above. Only add it if the target environment already has (or wants) a
theme-detection helper; otherwise just hardcode one CSS path as shown in
step 4.

## Files In This Skill

- `files/vimrc-snippet.vim` — the complete, copy-pasteable vimrc block
  (plugin declarations, CSS wiring, keybinding).
- `files/nord-dark.css` — Nord-palette dark theme for previm output.
- `files/nord-light.css` — Nord-palette light theme for previm output.
