local M = {}

local function get_visual_selection()
  local s_start = vim.fn.getpos("'<")
  local s_end = vim.fn.getpos("'>")
  local n_lines = math.abs(s_end[2] - s_start[2]) + 1
  local lines = vim.api.nvim_buf_get_lines(0, s_start[2] - 1, s_end[2], false)
  lines[1] = string.sub(lines[1], s_start[3], -1)
  if n_lines == 1 then
    lines[n_lines] = string.sub(lines[n_lines], 1, s_end[3] - s_start[3] + 1)
  else
    lines[n_lines] = string.sub(lines[n_lines], 1, s_end[3])
  end
  return table.concat(lines, '\n')
end

local raw =
'{ foo: bar, server: qq, objList: [{ a: start start start }, { a: b }, { a: end }], list: [ a0, a2, a1]}'

local function insert_line(line, indent)
  if indent > 0 then
    for _ = 0, indent, 1 do
      line = '  ' .. line
    end
  end
  print(line)
end

-- linebreak: true
-- foo: {
--   "foo": "bar"
-- }

-- linebreak: false
-- [
--   {
--      "foo": "bar"
--   }
-- ]


local function handle_keymap(input, indent, linebreak)
  local index = 0
  local indent = 0
  local in_word = false
  local line = ''
  for c in string.gmatch(raw, ".") do
    if index == 0 then
      insert_line(c, indent)
      indent = 1 -- the 1st line, either { or [
    elseif not in_word and c == ' ' then
      -- do nothing
    elseif not in_word and c ~= ' ' then
      in_word = true
      line = '"' .. c
    elseif c ~= ':' then
      in_word = false
      line = '"' .. c
    end
    index = index + 1
  end
end

local function handle_array(input)
end

local function handle_element(input)
end

function M.fmt()
  if (string.sub(raw, 1, 1) == '{') then
    handle_keymap(raw, 0, false)
  end
end

M.fmt()
return M
