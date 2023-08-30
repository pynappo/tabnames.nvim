A simple plugin that creates tab names that can be accessed via `t:name` or `vim.t.name`. Created for use with hand-crafting custom tablines.

# Installation

lazy.nvim:

```lua
{
    'pynappo/tabnames.nvim',
    config = function() -- calling setup is optional if you want defaults as shown here:
        local tabnames = require('tabnames')
        tabnames.setup({
            auto_suggest_names = true,
            default_tab_name = function(tabnr)
                return
                    tabnames.presets.special_tabs(tabnr)
                    or tabnames.presets.special_buffers(tabnr)
                    or tabnames.presets.short_tab_cwd(tabnr)
            end,
            session_support = false,
            update_default_tab_name = {'TabNewEntered', 'BufEnter'},
            setup_autocmds = true,
            setup_commands = true,
        })
    end
}
```

# Usage

`:TabRename {name}` to rename the current tab. If `name` is omitted, uses `default_tab_name(tabnr)` to reset the tab name. Variables like `%` are expanded.

`:TabRenameClear` to clear the current tab name.

Tab name can be accessed through `vim.t.name`, here's how I use it in my [heirline.nvim](https://github.com/rebelot/heirline.nvim) setup:

```lua
tabpage = {
    init = function(self) self.name = vim.t[self.tabnr].name end,
    provider = function(self) return '%' .. self.tabnr .. 'T ' .. self.tabnr .. (self.name and ' ' .. self.name or '') .. '%T' end,
    hl = function(self) return self.is_active and 'TabLineSel' or 'TabLine' end,
}
```

# API:
`require('tabnames').set_tab_name(tabnr, name, opts)`

- tabnr: tabpage number, can be 0 or nil for current tab
- name: string for manual naming, nil for default_tab_name
- opts: optional table with following keys:
    - notify: boolean or nil - whether or not vim.notify() notifies the user of the new tab name
- returns the new tab name
