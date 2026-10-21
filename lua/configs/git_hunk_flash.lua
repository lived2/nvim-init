local M = {}

local namespace = vim.api.nvim_create_namespace("GitHunkFlash")
local duration_ms = 600
local steps = 10
local states = {}

local function highlight_name(buf)
	return "GitHunkFlash" .. buf
end

local function rgb(color)
	return {
		math.floor(color / 0x10000) % 0x100,
		math.floor(color / 0x100) % 0x100,
		color % 0x100,
	}
end

local function blend(from, to, amount)
	local a = rgb(from)
	local b = rgb(to)
	local function channel(index)
		return math.floor(a[index] + (b[index] - a[index]) * amount + 0.5)
	end
	return channel(1) * 0x10000 + channel(2) * 0x100 + channel(3)
end

local function stop(buf)
	local state = states[buf]
	if state then
		states[buf] = nil
		state.timer:stop()
		state.timer:close()
	end
	if vim.api.nvim_buf_is_valid(buf) then
		vim.api.nvim_buf_clear_namespace(buf, namespace, 0, -1)
	end
end

local function find_current_hunk(buf, win)
	local hunks = require("gitsigns").get_hunks(buf) or {}
	local cursor_line = vim.api.nvim_win_get_cursor(win)[1]
	local line_count = vim.api.nvim_buf_line_count(buf)

	for _, hunk in ipairs(hunks) do
		local first = math.max(1, math.min(hunk.added.start, line_count))
		local count = hunk.added.count
		local last = count > 0 and math.min(first + count - 1, line_count) or first
		if cursor_line >= first and cursor_line <= last then
			return first, last
		end
	end
end

local function flash(buf, win)
	if
		not vim.api.nvim_buf_is_valid(buf)
		or not vim.api.nvim_buf_is_loaded(buf)
		or not vim.api.nvim_win_is_valid(win)
		or vim.api.nvim_win_get_buf(win) ~= buf
	then
		return
	end

	local first, last = find_current_hunk(buf, win)
	if not first then
		return
	end

	local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
	local cursorline = vim.api.nvim_get_hl(0, { name = "CursorLine", link = false })
	if not normal.bg or not cursorline.bg then
		return
	end

	stop(buf)
	local group = highlight_name(buf)
	vim.api.nvim_set_hl(0, group, { bg = cursorline.bg })

	for line = first, last do
		vim.api.nvim_buf_set_extmark(buf, namespace, line - 1, 0, {
			line_hl_group = group,
		})
	end

	local state = {
		timer = vim.uv.new_timer(),
		step = 1,
	}
	states[buf] = state
	local interval = math.floor(duration_ms / steps)

	state.timer:start(
		interval,
		interval,
		vim.schedule_wrap(function()
			if states[buf] ~= state or not vim.api.nvim_buf_is_valid(buf) then
				stop(buf)
				return
			end

			state.step = state.step + 1
			if state.step > steps then
				stop(buf)
				return
			end

			local amount = (state.step - 1) / (steps - 1)
			vim.api.nvim_set_hl(0, group, {
				bg = blend(cursorline.bg, normal.bg, amount),
			})
		end)
	)
end

function M.flash_current()
	local win = vim.api.nvim_get_current_win()
	flash(vim.api.nvim_win_get_buf(win), win)
end

function M.nav(direction)
	if direction ~= "next" and direction ~= "prev" then
		error(("Invalid hunk direction: %s"):format(tostring(direction)))
	end

	if vim.wo.diff then
		vim.cmd.normal({ direction == "next" and "]c" or "[c", bang = true })
		return
	end

	local win = vim.api.nvim_get_current_win()
	local buf = vim.api.nvim_win_get_buf(win)
	require("gitsigns").nav_hunk(direction, {}, function(err)
		if err then
			return
		end
		vim.schedule(function()
			flash(buf, win)
		end)
	end)
end

return M
