local M = {}

M.check = function()
  vim.health.start('Config format')

  local config, config_ok = vim.g.tabnames_config, true
  local config_format = {
    auto_suggest_names = { config.auto_suggest_names, { 'boolean' } },
    default_tab_name = {
      config.default_tab_name,
      function(arg)
        if arg == true then return false, 'tabnames: default_tab_name can only be either false or a boolean' end
        return vim.tbl_contains({ 'boolean', 'function' }, type(arg))
      end,
    },
    update_default_tab_name_events = { config.update_default_tab_name_events, { 'table' } },
    setup_autocmds = { config.setup_autocmds, { 'boolean' } },
    setup_commands = { config.setup_commands, { 'boolean' } },
  }
  vim.validate(config_format)

  for k, v in pairs(config) do
    if not config_format[k] then
      vim.health.warn('In vim.g.tabnames_config, ' .. k .. ' = ' .. tostring(v) .. ' is not a valid config key.')
    end
  end
  if config_ok then vim.health.ok('All the valid config options in vim.g.tabnames_config are set properly') end

  for tabnr, name in pairs(vim.json.decode(vim.g.TabnamesCache)) do
    if not vim.api.nvim_tabpage_is_valid(tabnr) then
      vim.health.error('Tab ' .. tabnr .. ' in the cache with name ' .. name .. " doesn't exist.")
    end
  end
end

return M
