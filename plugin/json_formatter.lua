vim.api.nvim_create_user_command("Fmt", require("json_formatter").fmt, {})
