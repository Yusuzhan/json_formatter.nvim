local M = {}

local handle_array, handle_keymap, handle_element, lines
lines = {}

local function subtable(tab, index)
	local sub = {}
	for i, value in ipairs(tab) do
		if i >= index then
			table.insert(sub, value)
		end
	end
	return sub
end

local function logv(msg)
	--print('\x1b[0;36;40m' .. msg .. '\x1b[0m')
	print(msg)
end

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

local function insert_line(line, indent)
	if indent > 0 then
		for _ = 0, indent, 1 do
			line = '  ' .. line
		end
	end
	table.insert(lines, line)
	--print(line)
end

function M.tokenize(input)
	local tokens = {}
	local word = ''
	local check_real_colon = false
	local last_char = ''
	for c in string.gmatch(input, ".") do
		if c == '\n' then
			c = ''
		end
		print('c: ' .. c .. ', last: ' .. last_char)
		if check_real_colon and c == ' ' then
			table.insert(tokens, '"' .. word .. '"')
			check_real_colon = false
			word = ''
			table.insert(tokens, ":")
		else
			check_real_colon = false
		end

		if c == ':' then
			check_real_colon = true
		elseif c == ',' and last_char == ':' then
			table.insert(tokens, '""')
		elseif c == '{' or c == '}' or c == ',' or c == '[' or c == ']' then
			if word ~= '' then
				table.insert(tokens, '"' .. word .. '"')
				word = ''
			end
			table.insert(tokens, c)
		elseif word == '' and (c == ' ' or c == '\n') then
			-- do nothing
		elseif word == '' and c ~= ' ' then
			word = c
		elseif word ~= '' and c ~= ' ' then
			word = word .. c
		end

		if (c ~= ' ') then
			last_char = c
		end
	end
	for key, value in pairs(tokens) do
		-- log(key .. ': ' .. value)
	end
	return tokens
end

function handle_keymap(tokens, indent, linebreak, start_index)
	logv('handle_keymap: ' .. tokens[start_index])
	local line = ''
	local index = start_index
	while true do
		logv('tokens[' .. index .. ']  ' .. tokens[index])
		if index == #tokens then
			insert_line('}', indent)
			break
		end
		if tokens[index] == '}' then
			logv('} FOUND' .. index)
			line = '}'
			if tokens[index + 1] == ',' then
				line = '},'
				index = index + 1
			end
			insert_line(line, indent)
			line = ''
			logv('MAP END index: ' .. index)
			return index
		elseif tokens[index] == '{' then
			logv('{ FOUND' .. index)
			insert_line('{', indent)
			index = index + 1
		elseif string.sub(tokens[index + 2], 1, 1) == '"' then
			logv('" FOUND' .. index)
			line = tokens[index] .. ': ' .. tokens[index + 2]
			index = index + 3
			if tokens[index + 1] == ',' then
				line = line .. ','
				index = index + 1
			end
			insert_line(line, indent + 1)
			line = ''
			-- next token after next is {
		elseif string.sub(tokens[index + 2], 1, 1) == '{' then
			logv('KEYMAP FOUND ' .. index)
			line = tokens[index] .. ': {'
			index = index + 2
			insert_line(line, indent + 1)
			line = ''
			index = handle_keymap(tokens, indent + 1, true, index + 1) + 1
		elseif string.sub(tokens[index + 2], 1, 1) == '[' then
			logv('[ FOUND' .. index)
			line = tokens[index] .. ': ['
			index = index + 2
			insert_line(line, indent + 1)
			line = ''
			index = handle_array(tokens, indent + 1, true, index + 1) + 1
			logv('^^^^^ index' .. index)
		else
			index = index + 1
		end
	end
end

function handle_array(tokens, indent, linebreak, start_index)
	local index = start_index
	local line = ''
	while true do
		logv('current index: ' .. index)
		if string.sub(tokens[index], 1, 1) == '{' then
			index = handle_keymap(tokens, indent + 1, false, index) + 1
		elseif string.sub(tokens[index], 1, 1) == '"' then
			-- elements array
			index = handle_element(tokens, indent + 1, index) + 1
		elseif tokens[index] == ']' then
			line = ']'
			logv("** FOUND ] " .. index)
			if tokens[index + 1] == ',' then
				logv("** FOUND ,")
				line = '],'
				index = index + 1
			end
			insert_line(line, indent)
			line = ''
			logv('LIST END index: ' .. index)
			return index
		else
			index = index + 1
		end
	end
end

function handle_element(tokens, indent, start_index)
	local index = start_index
	local line = tokens[start_index]
	if tokens[index + 1] == ',' then
		line = line .. ','
		index = index + 1
	end
	insert_line(line, indent)
	return index
end

-- for testing
function M.testFormat(tokens)
	handle_keymap(tokens, 0, false, 1)
end

local function insert_text_at_cursor(lines)
	local s_end = vim.fn.getpos("'>")
	-- 在光标位置插入文本
	-- print('s_end[2]: ' .. s_end[2])
	for i, value in ipairs(lines) do
		if string.find(value, "\n") then
			print("ysz found \\n" .. value)
		end
	end

	vim.api.nvim_buf_set_lines(0, s_end[2] + 1, s_end[2] + #lines, false, lines)
end

function M.fmt()
	local tokens = M.tokenize(get_visual_selection())
	for index, value in ipairs(tokens) do
		logv(index .. ': ' .. value)
	end
	handle_keymap(tokens, 0, false, 1)
	insert_text_at_cursor(lines)
end

return M
