vim.api.nvim_create_user_command("Fmt", require("json_formatter").fmt, {})
vim.cmd('command! -range -nargs=? Fmt lua require("json_formatter").fmt()')
