local M = {}

function M.on_save()
	local tabs = {}
	for _, tab in ipairs(vim.api.nvim_list_tabpages()) do
		local paths = {}
		for _, buf in ipairs(vim.t[tab].bufs or {}) do
			if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted and vim.bo[buf].buftype == "" then
				local path = vim.api.nvim_buf_get_name(buf)
				if path ~= "" then
					paths[#paths + 1] = path
				end
			end
		end
		tabs[#tabs + 1] = paths
	end
	return { tabs = tabs }
end

function M.on_post_load(data)
	-- Buffer IDs change between processes; rebuild the order from file paths.
	for index, tab in ipairs(vim.api.nvim_list_tabpages()) do
		local buffers = {}
		for _, path in ipairs((data.tabs or {})[index] or {}) do
			local buf = vim.fn.bufnr(path)
			if buf > 0 and vim.bo[buf].buflisted and not vim.tbl_contains(buffers, buf) then
				buffers[#buffers + 1] = buf
			end
		end
		vim.t[tab].bufs = buffers
	end
end

return M
