# tabnames.nvim

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
            default_tab_name = tabnames.tab_name_presets.short_tab_cwd, -- function(tabnr) returning string or number, or false
            experimental = {
                session_support = false,
            },
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
    provider = function(self) return '%' .. self.tabnr .. 'T ' .. self.tabnr .. (self.name and ' ' .. self.name or '') .. ' %T' end,
    hl = function(self) return self.is_active and 'TabLineSel' or 'TabLine' end,
}
```

# API:
`require('tabnames').set_tab_name(tabnr, name, notify, expand)` 

- notify and expand are booleans
- all values optional
- returns the new tab name
