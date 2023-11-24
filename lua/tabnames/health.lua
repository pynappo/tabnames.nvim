local M = {}

M.check = function()
  local config = vim.g.tabnames_config
  vim.health.start('Config format')
  if M.validate_config(config) then
    vim.health.ok('vim.g.tabnames_config is in the correct format')
  else
    vim.health.error('vim.g.tabnames_config is not accurate')
  end
end

M.validate_config = function(config)
  vim.validate({
    default_tab_name = {
      config.default_tab_name,
      function(arg)
        if arg == true then return false, 'tabnames: default_tab_name can only be either false or a boolean' end
        return vim.tbl_contains({ 'boolean', 'function' }, type(arg))
      end,
    },
    auto_suggest_names = { config.auto_suggest_names, { 'boolean' } },
    update_default_tab_name_events = { config.update_default_tab_name_events, { 'table' } },
    setup_autocmds = { config.setup_autocmds, { 'boolean' } },
    setup_commands = { config.setup_commands, { 'boolean' } }
  })
  return true
end

return M
