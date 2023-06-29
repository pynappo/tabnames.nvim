local tabnames = {}

tabnames.tab_name_presets = {
	tabnr = vim.api.nvim_tabpage_get_number,
	tab_cwd = function(tabnr) return vim.fn.getcwd(-1, tabnr) end,
	short_tab_cwd = function(tabnr) return vim.fn.pathshorten(tabnames.tab_name_presets.tab_cwd(tabnr)) end,
}

tabnames.config = {
	auto_suggest_names = true,
	default_tab_name = tabnames.tab_name_presets.short_tab_cwd,
	experimental = {
		session_support = false
	},
}

tabnames.cache = {}

function tabnames.cache_set(key, value)
	tabnames.cache[key] = value
	vim.g.TabnamesCache = vim.json.encode(tabnames.cache)
end

function tabnames.configure(opts)
	vim.validate({
		default_tab_name = { tabnames.config.default_tab_name, { 'function', 'boolean' } },
		auto_suggest_names = { tabnames.config.auto_suggest_names, { 'boolean' } },
		experimental = { tabnames.config.experimental, { 'table' } },
		['experimental.session_support'] = { tabnames.config.experimental.session_support, { 'table' } },
	})
	tabnames.config = vim.tbl_deep_extend('force', tabnames.config, opts or vim.g.tabnames_config or {})
end
function tabnames.setup(opts)
	tabnames.configure(opts)
	local tabnames_augroup = vim.api.nvim_create_augroup('Tabnames', { clear = true })

	if tabnames.config.experimental.session_support then
		vim.api.nvim_create_autocmd({ 'TabClosed', 'VimLeavePre' }, {
			group = tabnames_augroup,
			callback = function()
				local index = tonumber(vim.fn.expand('<afile>'))
				if not index then return end
				tabnames.cache_set(index, nil)
			end,
			desc = 'Auto-delete cached tab name',
		})
		vim.api.nvim_create_autocmd('SessionLoadPost', {
			group = tabnames_augroup,
			callback = function()
				if vim.g.TabnamesCache then
					local decoded = vim.json.decode(vim.g.TabnamesCache)
					for tabnr, name in pairs(decoded) do
						tabnames.set_tab_name(tonumber(tabnr), name)
					end
				end
			end
		})
	end

	if tabnames.config.default_tab_name then
		vim.api.nvim_create_autocmd({ 'TabNewEntered' }, {
			group = tabnames_augroup,
			callback = function() tabnames.set_tab_name() end,
			desc = 'Auto-set tab name',
		})
	end

	vim.api.nvim_create_user_command('TabRename',
		function(args) tabnames.set_tab_name(0, args.args, true) end,
		{
			desc = 'Rename the current tab',
			nargs = '*',
			complete = function()
				local results = {}
				local current_tabnr = vim.api.nvim_tabpage_get_number(0)
				if tabnames.config.auto_suggest_names then
					for _, preset in pairs(tabnames.tab_name_presets) do
						table.insert(results, preset(current_tabnr))
					end
				end
				return results
			end,
		}
	)
	vim.api.nvim_create_autocmd({'UIEnter'}, {
		group = tabnames_augroup,
		callback = function() tabnames.set_tab_name() end
	})
	vim.g.tabnames_loaded = true
end

function tabnames.set_tab_name(tabnr, name, notify)
	local current_tabnr = vim.api.nvim_tabpage_get_number(0)
	local current_tab = not tabnr or tabnr == 0 or tabnr == current_tabnr
	if current_tab then tabnr = vim.api.nvim_tabpage_get_number(0) end
	local tab_name = tostring(name and vim.fn.expand(name) or tabnames.config.default_tab_name(tabnr))
	vim.t[tabnr].name = tab_name
	if tabnames.config.experimental.session_support then
		tabnames.cache_set(tabnr, name)
	end
	if notify then
		vim.notify(
			'Renamed ' .. (current_tab and 'current tab' or ('tab #'.. tabnr)) .. (' to "%s"'):format(tab_name),
			vim.log.levels.INFO
		)
	end
	vim.cmd.doautocmd("User TabRenamed")
	return tab_name
end

return tabnames
