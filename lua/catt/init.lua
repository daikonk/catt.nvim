local M = {}

-- Default configuration
M.default_config = {
	file_patterns = { "*.catt" },
	indent_size = 4,
	diagnostics = {
		enable = true,
		update_in_insert = false,
		virtual_text = true,
	},
}

M.config = {}

-- Diagnostic namespace
local diagnostic_ns = vim.api.nvim_create_namespace("catt_diagnostics")

-- Define language syntax patterns
local syntax = {
	keywords = {
		control = { "if", "else", "while", "for", "return", "let", "fn" },
		builtins = { "meow", "meowln" },
	},
	operators = {
		arithmetic = { "+", "-", "*", "/", "%" },
		comparison = { "==", "!=", ">", "<" },
		logical = { "&&", "||", "!" },
	},
	delimiters = { "{", "}", "(", ")", "[", "]", ";", "," },
}

-- Parser for basic syntax validation
local function parse_line(line, line_num)
	local diagnostics = {}

	-- Check for unmatched brackets
	local brackets = {
		["{"] = "}",
		["["] = "]",
		["("] = ")",
	}
	local stack = {}

	for i = 1, #line do
		local char = line:sub(i, i)
		if brackets[char] then
			table.insert(stack, { char = char, pos = i - 1 })
		elseif vim.tbl_contains(vim.tbl_values(brackets), char) then
			if #stack == 0 then
				table.insert(diagnostics, {
					lnum = line_num - 1,
					col = i - 1,
					message = "Unmatched closing bracket",
					severity = vim.diagnostic.severity.ERROR,
				})
			else
				local last = table.remove(stack)
				if brackets[last.char] ~= char then
					table.insert(diagnostics, {
						lnum = line_num - 1,
						col = i - 1,
						message = "Mismatched brackets",
						severity = vim.diagnostic.severity.ERROR,
					})
				end
			end
		end
	end

	-- Check for incomplete statements
	if line:match(";%s*;") then
		table.insert(diagnostics, {
			lnum = line_num - 1,
			col = 0,
			message = "Empty statement",
			severity = vim.diagnostic.severity.WARN,
		})
	end

	-- Check for invalid operators
	local invalid_operators = line:match("[%+%-%*/%&%|=]{3,}")
	if invalid_operators then
		table.insert(diagnostics, {
			lnum = line_num - 1,
			col = line:find(invalid_operators) - 1,
			message = "Invalid operator sequence",
			severity = vim.diagnostic.severity.ERROR,
		})
	end

	return diagnostics
end

-- Set up treesitter highlighting
local function setup_treesitter()
	local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
	parser_config.catt = {
		install_info = {
			url = "https://github.com/tree-sitter/tree-sitter-javascript", -- Fallback to JavaScript parser for now
			files = { "src/parser.c" },
		},
		filetype = "catt",
	}

	-- Define highlights
	local highlights = {
		["@keyword"] = { link = "Keyword" },
		["@function"] = { link = "Function" },
		["@operator"] = { link = "Operator" },
		["@string"] = { link = "String" },
		["@number"] = { link = "Number" },
		["@variable"] = { link = "Identifier" },
		["@comment"] = { link = "Comment" },
	}

	for group, settings in pairs(highlights) do
		vim.api.nvim_set_hl(0, group, settings)
	end
end

-- Update diagnostics
local function update_diagnostics(bufnr)
	if not M.config.diagnostics.enable then
		return
	end

	local diagnostics = {}
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

	for i, line in ipairs(lines) do
		local line_diagnostics = parse_line(line, i)
		vim.list_extend(diagnostics, line_diagnostics)
	end

	vim.diagnostic.set(diagnostic_ns, bufnr, diagnostics, {
		virtual_text = M.config.diagnostics.virtual_text,
		update_in_insert = M.config.diagnostics.update_in_insert,
	})
end

function M.setup(opts)
	-- Merge user config with defaults
	M.config = vim.tbl_deep_extend("force", M.default_config, opts or {})

	-- Set up autocommands for diagnostics
	vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "TextChanged", "InsertLeave" }, {
		pattern = M.config.file_patterns,
		callback = function(ev)
			update_diagnostics(ev.buf)
		end,
	})

	-- Set up filetype detection
	vim.filetype.add({
		extension = {
			catt = "catt",
		},
	})

	-- Set up treesitter integration
	setup_treesitter()

	-- Set up basic editor config
	vim.api.nvim_create_autocmd("FileType", {
		pattern = "catt",
		callback = function()
			vim.bo.tabstop = M.config.indent_size
			vim.bo.shiftwidth = M.config.indent_size
			vim.bo.expandtab = true
			vim.bo.commentstring = "// %s"
		end,
	})
end

return M
