local M = {}

M.default_config = {
	file_patterns = { "*.cl" },
	indent_size = 4,
}

M.config = {}

local keywords = {
	["if"] = true,
	["else"] = true,
	["while"] = true,
	["for"] = true,
	["return"] = true,
	["let"] = true,
	["fn"] = true,

	-- built-ins
	["meow"] = true,
	["meowln"] = true,
}

-- define operator patterns
local operators = {
	["+"] = true,
	["-"] = true,
	["*"] = true,
	["/"] = true,
	["%"] = true,
	["=="] = true,
	["!="] = true,
	["&&"] = true,
	["||"] = true,
	["!"] = true,
	[">"] = true,
	["<"] = true,
}

local function get_indent_level(line, prev_line)
	local indent = 0
	if
		prev_line
		and (
			prev_line:match("if.*{%s*$")
			or prev_line:match("else.*{%s*$")
			or prev_line:match("while.*{%s*$")
			or prev_line:match("for.*{%s*$")
			or prev_line:match("fn.*{%s*$")
		)
	then
		indent = indent + 1
	end

	if line:match("^%s*}") then
		indent = indent - 1
	end

	return indent
end

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.default_config, opts or {})

	local syntax = vim.api.nvim_create_namespace("custom_lang_syntax")

	vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
		pattern = M.config.file_patterns,
		callback = function()
			vim.api.nvim_buf_clear_namespace(0, syntax, 0, -1)

			local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
			for i, line in ipairs(lines) do
				-- Highlight keywords
				for word in line:gmatch("%w+") do
					if keywords[word] then
						local start_col = line:find(word, 1, true) - 1
						vim.api.nvim_buf_add_highlight(0, syntax, "Keyword", i - 1, start_col, start_col + #word)
					end
				end

				-- Highlight operators
				for op in line:gmatch("[%+%-%*/%=%!%&%|><]+") do
					if operators[op] then
						local start_col = line:find(op, 1, true) - 1
						vim.api.nvim_buf_add_highlight(0, syntax, "Operator", i - 1, start_col, start_col + #op)
					end
				end

				-- Highlight strings
				for str in line:gmatch('"[^"]*"') do
					local start_col = line:find(str, 1, true) - 1
					vim.api.nvim_buf_add_highlight(0, syntax, "String", i - 1, start_col, start_col + #str)
				end

				-- Highlight numbers
				for num in line:gmatch("%d+") do
					local start_col = line:find(num, 1, true) - 1
					vim.api.nvim_buf_add_highlight(0, syntax, "Number", i - 1, start_col, start_col + #num)
				end
			end
		end,
	})

	vim.api.nvim_create_autocmd("BufWritePre", {
		pattern = M.config.file_patterns,
		callback = function()
			local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
			local new_lines = {}
			local indent_level = 0

			for i, line in ipairs(lines) do
				local prev_line = i > 1 and lines[i - 1] or nil
				indent_level = indent_level + get_indent_level(line, prev_line)
				local indent_str = string.rep(string.rep(" ", M.config.indent_size), math.max(0, indent_level))
				local trimmed_line = line:match("^%s*(.-)%s*$")
				table.insert(new_lines, indent_str .. trimmed_line)
			end

			vim.api.nvim_buf_set_lines(0, 0, -1, false, new_lines)
		end,
	})
end

return M
