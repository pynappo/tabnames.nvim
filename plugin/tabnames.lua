if vim.g.tabnames_loaded then return end
require('tabnames').setup()
vim.g.tabnames_loaded = true
