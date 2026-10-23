# Workspace sessions

- `<Leader>ss` or `:WorkspaceSave`: save the current workspace.
- `<Leader>sl` or `:WorkspaceLoad`: restore the current workspace.
- `<Leader>sd` or `:WorkspaceDelete`: select a saved session to delete, then disable
  exit autosave for this Neovim instance. Canceling leaves autosave enabled.
- Start Neovim to restore the current workspace automatically, including when file arguments are supplied.
- Exit Neovim to save automatically.

When no snapshot exists, the normal startup layout is used. Explicit file
arguments are kept alongside the restored buffers, and the first file is shown
in a code window. The workspace is still selected by global cwd, not the file's
parent directory. Stdin skips automatic restoration, as does a file opened by
another startup command when no file arguments were supplied.
Successful restoration replaces the default Neo-tree startup layout.

The workspace key is the global working directory (`:pwd` unless a window/tab
has a local directory), normalized and hashed to avoid filename collisions.
Sessions are stored under `stdpath("data")/workspace-sessions/`, outside the
project. On Linux this is normally `~/.local/share/nvim/workspace-sessions/`.
On Windows it is normally `%LOCALAPPDATA%\nvim-data\workspace-sessions\`.
To check the actual path (including custom XDG paths or NVIM_APPNAME), run:

```vim
:lua print(vim.fn.stdpath("data") .. "/workspace-sessions")
```

Each JSON snapshot contains named file buffers, code window layouts, cursor
positions, breakpoints (including conditions, hit conditions and log messages),
the NvChad buffer-tab order for each tabpage, and visible Neo-tree sidebars.
Existing buffer-tab positions are preserved when startup file arguments are
merged; new files are appended. Older snapshots acquire ordering information
the next time they are saved.
Filesystem sidebars restore their root, width,
expanded folders and selected path. Other sources are refreshed from current
data; Symbols requires an attached language server. Floating Neo-tree windows
are not saved. Noice, Telescope and DAP temporary buffers are excluded; the
resession default quickfix extension remains enabled.
For the active tab, the last explicitly selected source takes precedence over a
buffer replaced by a delayed filesystem-follow refresh in the same sidebar.

The snapshot represents one workspace per Neovim instance, including its tabs.
To work with a different workspace in the same instance, change the global cwd
with `:cd` and explicitly save or restore that workspace.

Automatic saving will not overwrite an existing snapshot unless it was saved
or restored in this instance. Use `WorkspaceSave` to explicitly replace an
unrestored snapshot.
An empty instance does not overwrite a snapshot.

Unsaved edits are not stored in the snapshot. Restore refuses to replace modified
buffers or an active debug session. Missing breakpoint files and line numbers
beyond the end of a file are skipped; source edits can still move a breakpoint's
intended location. The running debugger itself is not restored.
