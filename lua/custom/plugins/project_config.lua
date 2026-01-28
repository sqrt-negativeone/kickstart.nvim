return {
  {
    dir = '~/.config/nvim/lua/custom/plugins/project-config',
    config = function()
      require('custom/plugins/project-config').setup {
        indent = {
          expandtab = true,
          shiftwidth = 2,
        },
      }
    end,
  },
}
