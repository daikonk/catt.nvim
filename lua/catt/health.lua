local M = {}

function M.check()
	local health = vim.health or require("health")

	health.report_start("Catt language plugin")

	if vim.fn.has("nvim-0.8.0") == 1 then
		health.report_ok("Neovim version >= 0.8.0")
	else
		health.report_error("Neovim version must be >= 0.8.0")
	end
end

return M
