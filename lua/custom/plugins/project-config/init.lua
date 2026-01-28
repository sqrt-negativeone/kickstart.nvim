-- Project Configuration Module for Neovim
-- Provides per-project: keymaps, build/debug scripts, file opening, indentation

local M = {}

-- Default configuration
M.defaults = {
  -- Build and run configuration
  build_cmd = nil, -- Command to build the project
  run_cmd = nil, -- Command to run the project
  debug_config = nil, -- DAP debug configuration

  -- File opening configuration
  file_extensions = {}, -- Extensions to open (e.g., {"lua", "py", "js"})
  exclude_patterns = {}, -- Glob patterns to exclude (e.g., {"**/node_modules/**", "**/.git/**"})
  root_dir = nil, -- Project root (defaults to cwd)

  -- Indentation rules
  indent = {
    expandtab = true, -- Use spaces instead of tabs
    shiftwidth = 2, -- Indentation width
    tabstop = 2, -- Tab width
    softtabstop = 2, -- Soft tab width
  },

  -- Custom keymaps (key = command)
  keymaps = {},
}

-- Current project configuration
M.config = {}

-- Find project root by looking for common project markers
local function find_project_root()
  local markers = {
    '.project.lua', -- Our project config file
    '.git',
    'package.json',
    'Cargo.toml',
    'pyproject.toml',
    'Makefile',
    'CMakeLists.txt',
    'go.mod',
    '.projectile',
  }

  local path = vim.fn.expand '%:p:h'
  if path == '' then
    path = vim.fn.getcwd()
  end

  while path ~= '/' do
    for _, marker in ipairs(markers) do
      if vim.fn.filereadable(path .. '/' .. marker) == 1 or vim.fn.isdirectory(path .. '/' .. marker) == 1 then
        return path
      end
    end
    path = vim.fn.fnamemodify(path, ':h')
  end

  return vim.fn.getcwd()
end

-- Load project configuration from .project.lua
local function load_project_config(root)
  local config_path = root .. '/.project.lua'
  if vim.fn.filereadable(config_path) == 1 then
    local ok, project_config = pcall(dofile, config_path)
    if ok and type(project_config) == 'table' then
      return project_config
    else
      vim.notify('Error loading .project.lua: ' .. tostring(project_config), vim.log.levels.ERROR)
    end
  end
  return {}
end

-- Apply indentation settings
local function apply_indent_settings(indent_config)
  if not indent_config then
    return
  end

  if indent_config.expandtab ~= nil then
    vim.opt_local.expandtab = indent_config.expandtab
  end
  if indent_config.shiftwidth then
    vim.opt_local.shiftwidth = indent_config.shiftwidth
  end
  if indent_config.tabstop then
    vim.opt_local.tabstop = indent_config.tabstop
  end
  if indent_config.softtabstop then
    vim.opt_local.softtabstop = indent_config.softtabstop
  end
end

-- Build the project
function M.build()
  local cmd = M.config.build_cmd
  if not cmd then
    vim.notify('No build command configured for this project', vim.log.levels.WARN)
    return
  end

  -- Save all buffers first
  vim.cmd 'wall'

  if type(cmd) == 'function' then
    cmd()
  elseif type(cmd) == 'string' then
    -- Use terminal or quickfix
    if M.config.build_in_terminal then
      vim.cmd('split | terminal ' .. cmd)
    else
      vim.cmd('compiler! ' .. (M.config.compiler or ''))
      vim.fn.setqflist({}, 'r')
      vim.cmd("cexpr system('" .. cmd:gsub("'", "'\\''") .. "')")
      vim.cmd 'copen'
    end
  end
end

-- Run the project in debugger (DAP)
function M.debug()
  local dap_ok, dap = pcall(require, 'dap')
  if not dap_ok then
    vim.notify('nvim-dap is not installed', vim.log.levels.ERROR)
    return
  end

  local debug_config = M.config.debug_config
  if not debug_config then
    vim.notify('No debug configuration for this project', vim.log.levels.WARN)
    return
  end

  -- Save all buffers first
  vim.cmd 'wall'

  if type(debug_config) == 'function' then
    debug_config(dap)
  elseif type(debug_config) == 'table' then
    dap.run(debug_config)
  end
end

-- Run the project (non-debug)
function M.run()
  local cmd = M.config.run_cmd
  if not cmd then
    vim.notify('No run command configured for this project', vim.log.levels.WARN)
    return
  end

  vim.cmd 'wall'

  if type(cmd) == 'function' then
    cmd()
  elseif type(cmd) == 'string' then
    vim.cmd('split | terminal ' .. cmd)
  end
end

-- Open all project files matching extensions (excluding patterns)
function M.open_project_files()
  local extensions = M.config.file_extensions
  local exclude_patterns = M.config.exclude_patterns or {}
  local root = M.config.root_dir or find_project_root()

  if #extensions == 0 then
    vim.notify('No file extensions configured', vim.log.levels.WARN)
    return
  end

  -- Build find command
  local ext_pattern = table.concat(
    vim.tbl_map(function(ext)
      return "-name '*." .. ext .. "'"
    end, extensions),
    ' -o '
  )

  local exclude_args = table.concat(
    vim.tbl_map(function(pat)
      -- Convert glob to find-compatible pattern
      return "-path '" .. pat .. "' -prune -o"
    end, exclude_patterns),
    ' '
  )

  local cmd = string.format('find %s %s \\( %s \\) -type f -print 2>/dev/null', vim.fn.shellescape(root), exclude_args, ext_pattern)

  local handle = io.popen(cmd)
  if not handle then
    vim.notify('Failed to find project files', vim.log.levels.ERROR)
    return
  end

  local files = {}
  for file in handle:lines() do
    table.insert(files, file)
  end
  handle:close()

  if #files == 0 then
    vim.notify('No matching files found', vim.log.levels.INFO)
    return
  end

  -- Open files
  for _, file in ipairs(files) do
    vim.cmd('badd ' .. vim.fn.fnameescape(file))
  end

  vim.notify(string.format('Opened %d files', #files), vim.log.levels.INFO)
end

-- Setup keymaps
local function setup_keymaps()
  local opts = { noremap = true, silent = true }

  -- Default F-key mappings
  vim.keymap.set('n', '<F1>', M.build, vim.tbl_extend('force', opts, { desc = 'Build project' }))
  vim.keymap.set('n', '<F2>', M.debug, vim.tbl_extend('force', opts, { desc = 'Debug project' }))
  vim.keymap.set('n', '<F3>', M.run, vim.tbl_extend('force', opts, { desc = 'Run project' }))
  vim.keymap.set('n', '<F4>', M.open_project_files, vim.tbl_extend('force', opts, { desc = 'Open project files' }))

  -- Custom keymaps from project config
  if M.config.keymaps then
    for key, action in pairs(M.config.keymaps) do
      if type(action) == 'string' then
        vim.keymap.set('n', key, action, opts)
      elseif type(action) == 'function' then
        vim.keymap.set('n', key, action, opts)
      elseif type(action) == 'table' then
        vim.keymap.set(action.mode or 'n', key, action.cmd or action[1], vim.tbl_extend('force', opts, { desc = action.desc }))
      end
    end
  end
end

-- Initialize the plugin
function M.setup(opts)
  opts = opts or {}
  M.defaults = vim.tbl_deep_extend('force', M.defaults, opts)

  -- Create autocommand group
  local group = vim.api.nvim_create_augroup('ProjectConfig', { clear = true })

  -- Load project config when entering a buffer
  vim.api.nvim_create_autocmd({ 'BufEnter', 'DirChanged' }, {
    group = group,
    callback = function()
      M.load()
    end,
  })

  -- Apply indent settings on FileType
  vim.api.nvim_create_autocmd('FileType', {
    group = group,
    callback = function()
      if M.config.indent then
        apply_indent_settings(M.config.indent)
      end
      -- Per-filetype indent overrides
      if M.config.indent_by_filetype then
        local ft = vim.bo.filetype
        if M.config.indent_by_filetype[ft] then
          apply_indent_settings(M.config.indent_by_filetype[ft])
        end
      end
    end,
  })

  -- Initial load
  M.load()
end

-- Load/reload project configuration
function M.load()
  local root = find_project_root()
  local project_config = load_project_config(root)

  M.config = vim.tbl_deep_extend('force', {}, M.defaults, project_config)
  M.config.root_dir = M.config.root_dir or root

  setup_keymaps()
  M.open_project_files()

  -- Apply indent settings to current buffer
  if M.config.indent then
    apply_indent_settings(M.config.indent)
  end
end

-- Reload project configuration
function M.reload()
  M.load()
  vim.notify('Project configuration reloaded', vim.log.levels.INFO)
end

-- User command to reload config
vim.api.nvim_create_user_command('ProjectReload', M.reload, { desc = 'Reload project configuration' })
vim.api.nvim_create_user_command('ProjectBuild', M.build, { desc = 'Build project' })
vim.api.nvim_create_user_command('ProjectDebug', M.debug, { desc = 'Debug project' })
vim.api.nvim_create_user_command('ProjectRun', M.run, { desc = 'Run project' })
vim.api.nvim_create_user_command('ProjectOpenFiles', M.open_project_files, { desc = 'Open project files' })

return M
