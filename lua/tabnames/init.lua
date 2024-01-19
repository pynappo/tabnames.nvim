local tabnames = {}
local g, api, fn = vim.g, vim.api, vim.fn

-- Some presets for tab naming
--- @type table<string, fun(int?): string|nil|false>
tabnames.presets = {
  tabnr = api.nvim_tabpage_get_number,
  short_tab_cwd = function(tabnr) return fn.pathshorten(fn.getcwd(-1, tabnr)) end,
  short_active_buffer_name = function(tabnr)
    local active_buffer = api.nvim_win_get_buf(api.nvim_tabpage_get_win(tabnr))
    local active_buffer_name = tabnames.presets.special_buffers(tabnr) or api.nvim_buf_get_name(active_buffer)
    return fn.pathshorten(active_buffer_name)
  end,
  special_buffers = function(tabnr)
    local active_buffer = api.nvim_win_get_buf(api.nvim_tabpage_get_win(tabnr))
    if vim.bo[active_buffer].buftype == 'nofile' then
      local expanded = fn.expand('%:t')
      return type(expanded) == 'table' and expanded[1] or expanded
    end
  end,
  special_tabs = function(tabnr)
    if vim.t[tabnr].diffview_view_initialized then return 'Diffview' end
  end,
}

tabnames.cache = {}

-- also update ./health.lua if you update this
g.tabnames_config = {
  auto_suggest_names = true,
  default_tab_name = function(tabnr)
    return tabnames.presets.special_tabs(tabnr)
      or tabnames.presets.special_buffers(tabnr)
      or tabnames.presets.short_tab_cwd(tabnr)
  end,
  update_default_tab_name_events = { 'TabNewEntered', 'BufEnter' },
  setup_autocmds = true,
  setup_commands = true,
}

function tabnames.cache_set(key, value)
  tabnames.cache[key] = value
  g.TabnamesCache = vim.json.encode(tabnames.cache)
end

function tabnames.setup(opts)
  tabnames.configure(opts)
  local tabnames_augroup = api.nvim_create_augroup('Tabnames', { clear = true })
  if g.tabnames_config.setup_autocmds then tabnames.setup_autocmds(tabnames_augroup) end
  if g.tabnames_config.setup_commands then tabnames.setup_commands() end
end

function tabnames.configure(opts)
  local config = opts and vim.tbl_deep_extend('force', g.tabnames_config, opts) or g.tabnames_config
  g.tabnames_config = config
  return g.tabnames_config
end

function tabnames.setup_autocmds(augroup)
  local config = g.tabnames_config
  local autocmd = api.nvim_create_autocmd
  autocmd({ 'TabClosed', 'VimLeavePre' }, {
    group = augroup,
    callback = function(details)
      local index = tonumber(fn.expand(details.match))
      if index then tabnames.cache_set(index, nil) end
    end,
    desc = 'Auto-delete cached tab name',
  })
  autocmd('SessionLoadPost', {
    group = augroup,
    callback = function()
      if g.TabnamesCache then
        for tabnr, name in pairs(vim.json.decode(g.TabnamesCache)) do
          tabnames.set_tab_name(tonumber(tabnr), name)
        end
      end
    end,
    desc = 'Load saved stuff',
  })
  autocmd({ 'UIEnter' }, {
    group = augroup,
    callback = function() tabnames.set_tab_name() end,
    desc = 'Auto-set tab name on startup',
  })

  if config.default_tab_name then
    autocmd(config.update_default_tab_name_events, {
      group = augroup,
      callback = function()
        if not vim.t.manual_rename then tabnames.set_tab_name() end
      end,
      desc = 'Auto-set tab name',
    })
  end
end

function tabnames.setup_commands()
  local config = g.tabnames_config
  local function complete(arglead, cmdline, curpos)
    local results = {}
    if config.auto_suggest_names and #cmdline == 10 then
      local current_tabnr = api.nvim_tabpage_get_number(0)
      for _, preset in pairs(tabnames.presets) do
        local result = preset(current_tabnr)
        if result and result ~= '' then table.insert(results, result) end
      end
    end
    return results
  end
  api.nvim_create_user_command(
    'TabRename',
    function(args) tabnames.set_tab_name(0, args.args, { message = true }) end,
    {
      desc = 'Rename the current tab',
      nargs = '*',
      complete = complete,
    }
  )
  api.nvim_create_user_command(
    'TabRenameClear',
    function() tabnames.set_tab_name(0, nil, { message = true }) end,
    { desc = 'Clear current tab name, reverting back to default' }
  )
end

function tabnames.set_tab_name(tabnr, new_name, opts)
  local current_tab = not tabnr or tabnr == 0 or tabnr == api.nvim_tabpage_get_number(0)
  if current_tab then tabnr = api.nvim_tabpage_get_number(0) end
  if not api.nvim_tabpage_is_valid(tabnr) then
    vim.notify('tabnames: tabpage #' .. tabnr .. ' is invalid', vim.log.levels.ERROR)
    return false
  end

  local old_name = vim.t[tabnr].name
  local manual_rename = new_name ~= nil

  opts = opts or {}
  local config = g.tabnames_config

  if not manual_rename and type(config.default_tab_name) == 'function' then
    new_name = config.default_tab_name(tabnr)
  end
  new_name = fn.expand(tostring(new_name))

  vim.t[tabnr].name = new_name
  vim.t[tabnr].manual_rename = manual_rename
  tabnames.cache_set(tabnr, new_name)

  if opts.notify then
    vim.notify(
      'Renamed ' .. (current_tab and 'current tab' or ('tab #' .. tabnr)) .. (' to "%s"'):format(new_name),
      vim.log.levels.INFO
    )
  end
  if opts.message then
    vim.print('Renamed ' .. (current_tab and 'current tab' or ('tab #' .. tabnr)) .. (' to "%s"'):format(new_name))
  end
  api.nvim_exec_autocmds({ 'User' }, {
    pattern = 'TabRenamed',
    data = {
      old_name = old_name,
      new_name = new_name,
      manual_rename = manual_rename,
    },
  })

  return vim.t[tabnr].name
end

return tabnames
