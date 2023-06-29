local tabnames = {}

tabnames.tab_name_presets = {
	tabnr = vim.api.nvim_tabpage_get_number,
	tab_cwd = function(tabnr) return vim.fn.getcwd(-1, tabnr) end,
	short_tab_cwd = function(tabnr) return vim.fn.pathshorten(tabnames.tab_name_presets.tab_cwd(tabnr)) end,
}

tabnames.cache = {}

vim.g.tabnames_config = {
	auto_suggest_names = true,
	default_tab_name = tabnames.tab_name_presets.short_tab_cwd,
	experimental = {
		session_support = false
	},
}

function tabnames.cache_set(key, value)
	tabnames.cache[key] = value
	vim.g.TabnamesCache = vim.json.encode(tabnames.cache)
end

function tabnames.configure(opts)
	local config = vim.tbl_deep_extend('force', vim.g.tabnames_config, opts or {})
	vim.print(config)
	vim.validate({
		default_tab_name = {
			config.default_tab_name,
			function(arg)
				if arg == true then return false, 'tabnames: default_tab_name cannot be set to true' end
				return vim.tbl_contains({ 'boolean', 'function' }, type(arg))
			end,
		},
		auto_suggest_names = { config.auto_suggest_names, { 'boolean' } },
		experimental = { config.experimental, { 'table' } },
		['experimental.session_support'] = { config.experimental.session_support, { 'boolean' } },
	})
	vim.g.tabnames_config = config
end

function tabnames.setup(opts)
	tabnames.configure(opts)

	local tabnames_augroup = vim.api.nvim_create_augroup('Tabnames', { clear = true })
	local config = vim.g.tabnames_config
	if config.experimental.session_support then
		vim.api.nvim_create_autocmd({ 'TabClosed', 'VimLeavePre' }, {
			group = tabnames_augroup,
			callback = function()
				local index = tonumber(vim.fn.expand('<afile>'))
				if index then tabnames.cache_set(index, nil) end
			end,
			desc = 'Auto-delete cached tab name',
		})
		vim.api.nvim_create_autocmd('SessionLoadPost', {
			group = tabnames_augroup,
			callback = function()
				if vim.g.TabnamesCache then
					for tabnr, name in pairs(vim.json.decode(vim.g.TabnamesCache)) do
						tabnames.set_tab_name(tonumber(tabnr), name)
					end
				end
			end
		})
	end

	if config.default_tab_name then
		vim.api.nvim_create_autocmd({ 'TabNewEntered' }, {
			group = tabnames_augroup,
			callback = function() tabnames.set_tab_name() end,
			desc = 'Auto-set tab name',
		})
	end
	vim.api.nvim_create_autocmd({ 'UIEnter' }, {
		group = tabnames_augroup,
		callback = function() tabnames.set_tab_name() end
	})

	vim.api.nvim_create_user_command('TabRename',
		function(args) tabnames.set_tab_name(0, args.args, true, true) end,
		{
			desc = 'Rename the current tab',
			nargs = '*',
			complete = function()
				if config.auto_suggest_names then
					local current_tabnr = vim.api.nvim_tabpage_get_number(0)
					return vim.tbl_map(function(preset) return preset(current_tabnr) end, tabnames.tab_name_presets)
				end
				return {}
			end,
		}
	)
	vim.api.nvim_create_user_command('TabRenameClear',
		function() tabnames.set_tab_name(0, '', true) end,
		{
			desc = 'Clear the current tab name',
			nargs = '*',
			complete = function() end,
		}
	)

	vim.g.tabnames_loaded = true
end

function tabnames.set_tab_name(tabnr, name, notify, expand)
	local config = vim.g.tabnames_config
	local current_tab = not tabnr or tabnr == 0 or tabnr == vim.api.nvim_tabpage_get_number(0)
	if current_tab then tabnr = vim.api.nvim_tabpage_get_number(0) end
	local tabname = name
	if not name and type(config.default_tab_name) == 'function' then name = config.default_tab_name(tabnr) end
	tabname = tostring(tabname)
	if expand then tabname = vim.fn.expand(tabname) end

	vim.t[tabnr].name = tabname
	if config.experimental.session_support then tabnames.cache_set(tabnr, tabname) end

	if notify then
		vim.notify(
			'Renamed ' .. (current_tab and 'current tab' or ('tab #' .. tabnr)) .. (' to "%s"'):format(tabname),
			vim.log.levels.INFO
		)
	end

	vim.cmd.doautocmd("User TabRenamed")
	return tabname
end

return tabnames
