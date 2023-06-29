# nvim-tabnames

A simple plugin that creates tab names that can be accessed via `t:name` or `vim.t.name`. Meant for use with hand-crafting custom tablines.

# Installation

lazy.nvim:

```lua
{
    'pynappo/nvim-tabnames',
    config = function() -- calling setup is optional if you want defaults as shown here:
        local tabnames = require('tabnames')
        tabnames.setup({
            auto_suggest_names = true,
            default_tab_name = tabnames.tab_name_presets.short_tab_cwd, -- function(bufnr): string, or false
            experimental = {
                session_support = false,
            },
        })
    end
}
```

# Usage

`:TabRename {name}` to rename the current tab. If `name` is omitted, uses `default_tab_name(bufnr)` to reset the tab name.

Name can be accessed through `vim.t.name`, here's how I use it in my [heirline.nvim](https://github.com/rebelot/heirline.nvim) setup:

```lua
tabpage = {
    init = function(self) self.name = vim.t[self.tabnr].name end,
    provider = function(self) return '%' .. self.tabnr .. 'T ' .. self.tabnr .. (self.name and ' ' .. self.name or '') .. ' %T' end,
    hl = function(self) return self.is_active and 'TabLineSel' or 'TabLine' end,
}
```

# API:
`require('tabnames').set_tab_name(tabnr, name, notify)`, all values optional
