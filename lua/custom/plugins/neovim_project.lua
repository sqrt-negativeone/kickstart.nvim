return {
  {
    'coffebar/neovim-project',
    opts = {
      -- Project directories
      projects = {
        '~/.config/nvim/',
        '~/journee/ojin/managed-models/avatar',
        '~/journee/ojin/managed-models/tts',
        '~/journee/ojin/inference-proxy/',
        '~/journee/ojin/widget/',
      },
      -- Ignore directories
      -- Useful if you have something like "~/projects/*.worktrees/*" in
      -- projects and want to filter out the parent directory with
      -- ignore_projects = { "~/projects/*.worktrees/" }
      ignore_projects = {},
      -- Path to store history and sessions
      datapath = vim.fn.stdpath 'data', -- ~/.local/share/nvim/
      -- Load the most recent session on startup if not in the project directory
      last_session_on_startup = true,
      -- Dashboard mode prevent session autoload on startup
      dashboard_mode = false,
      -- Timeout in milliseconds before trigger FileType autocmd after session load
      -- to make sure lsp servers are attached to the current buffer.
      -- Set to 0 to disable triggering FileType autocmd
      filetype_autocmd_timeout = 200,
      -- Keymap to delete project from history in Telescope picker
      forget_project_keys = {
        -- insert mode: Ctrl+d
        i = '<C-d>',
        -- normal mode: d
        n = 'd',
      },
      -- Follow symbolic links in glob patterns (affects startup speed)
      -- "full" or true - follow symlinks in all matched directories
      -- "partial" - follow symlinks before any matching operators (*, ?, [])
      -- "none" or false or nil - do not follow symlinks
      follow_symlinks = 'full',
      -- Enable per-branch session management
      -- When true, sessions are stored separately for each git branch
      -- Switching branches will automatically save current session and load branch-specific session
      -- Requires git to be installed in the system
      per_branch_sessions = false,
      -- Enable debug logging
      -- When true, logs debug information to ~/.local/share/nvim/neovim-project-debug.log
      -- Useful for troubleshooting plugin behavior
      debug_logging = false,

      -- Overwrite some of Session Manager options
      session_manager_opts = {
        autosave_ignore_dirs = {
          vim.fn.expand '~', -- don't create a session for $HOME/
          '/tmp',
        },
        autosave_ignore_filetypes = {
          -- All buffers of these file types will be closed before the session is saved
          'ccc-ui',
          'dap-repl',
          'dap-view',
          'dap-view-term',
          'gitcommit',
          'gitrebase',
          'qf',
          'toggleterm',
        },
      },
      -- Picker to use for project selection
      -- Options: "telescope", "fzf-lua", "snacks"
      -- Fallback to builtin select ui if the specified picker is not available
      picker = {
        type = 'telescope', -- one of "telescope", "fzf-lua", or "snacks"

        preview = {
          enabled = true, -- show directory structure in Telescope preview
          git_status = true, -- show branch name, an ahead/behind counter, and the git status of each file/folder
          git_fetch = false, -- fetch from remote, used to display the number of commits ahead/behind, requires git authorization
          show_hidden = true, -- show hidden files/folders
        },
        opts = {
          -- picker-specific options
        },
      },
    },
    init = function()
      -- enable saving the state of plugins in the session
      vim.opt.sessionoptions:append 'globals' -- save global variables that start with an uppercase letter and contain at least one lowercase letter.
    end,

    dependencies = {
      { 'nvim-lua/plenary.nvim' },
      -- optional picker
      { 'nvim-telescope/telescope.nvim', tag = '0.1.4' },
      -- optional picker
      { 'ibhagwan/fzf-lua' },
      -- optional picker
      { 'folke/snacks.nvim' },
      { 'Shatur/neovim-session-manager' },
    },
    lazy = false,
    priority = 100,
  },
}
