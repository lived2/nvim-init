local M = {}

local group_prefix = "BufferFocusCursorLine"
local duration_ms = 600
local steps = 10
local timers = {}
local last_win
local last_buf

local function rgb(color)
	return {
		bit.rshift(color, 16),
		bit.band(bit.rshift(color, 8), 0xff),
		bit.band(color, 0xff),
	}
end

local function blend(from, to, amount)
	local a = rgb(from)
	local b = rgb(to)
	local function channel(index)
		return math.floor(a[index] + (b[index] - a[index]) * amount + 0.5)
	end
	return bit.lshift(channel(1), 16) + bit.lshift(channel(2), 8) + channel(3)
end

local function define_highlights()
	local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
	local cursorline = vim.api.nvim_get_hl(0, { name = "CursorLine", link = false })
	if not normal.bg then
		return false
	end

	local flash = cursorline.bg or normal.bg
	-- Start with a softened CursorLine color, then blend back into Normal.
	flash = blend(normal.bg, flash, 0.55)
	for step = 1, steps do
		local amount = (step - 1) / (steps - 1)
		vim.api.nvim_set_hl(0, group_prefix .. step, {
			bg = blend(flash, normal.bg, amount),
		})
	end
	return true
end

local function cursorline_target(value)
	for item in value:gmatch("[^,]+") do
		local key, target = item:match("^([^:]+):(.+)$")
		if key == "CursorLine" then
			return target
		end
	end
end

local function set_cursorline_target(value, target)
	local items = {}
	local replaced = false
	for item in value:gmatch("[^,]+") do
		local key = item:match("^([^:]+):")
		if key == "CursorLine" then
			if target then
				items[#items + 1] = "CursorLine:" .. target
			end
			replaced = true
		else
			items[#items + 1] = item
		end
	end
	if target and not replaced then
		items[#items + 1] = "CursorLine:" .. target
	end
	return table.concat(items, ",")
end

local function stop(win)
	local state = timers[win]
	if not state then
		return
	end
	timers[win] = nil
	state.timer:stop()
	state.timer:close()

	if not vim.api.nvim_win_is_valid(win) then
		return
	end
	local current = vim.wo[win].winhighlight
	local target = cursorline_target(current)
	if target and vim.startswith(target, group_prefix) then
		vim.wo[win].winhighlight = set_cursorline_target(current, state.original_target)
	end
	if vim.wo[win].cursorlineopt == "both" then
		vim.wo[win].cursorlineopt = state.cursorlineopt
	end
	if not state.cursorline and vim.wo[win].cursorline then
		vim.wo[win].cursorline = false
	end
end

local function eligible(win, buf)
	if vim.api.nvim_win_get_config(win).relative ~= "" then
		return false
	end
	return vim.bo[buf].buftype == "" or vim.bo[buf].filetype == "neo-tree"
end

local function clear_inherited_flash(win)
	if not vim.api.nvim_win_is_valid(win) then
		return
	end
	local current = vim.wo[win].winhighlight
	local target = cursorline_target(current)
	if target and vim.startswith(target, group_prefix) then
		vim.wo[win].winhighlight = set_cursorline_target(current, nil)
		if vim.wo[win].cursorlineopt == "both" then
			vim.wo[win].cursorlineopt = "number"
		end
	end
end

local function flash(win, buf)
	if not vim.api.nvim_win_is_valid(win) or not vim.api.nvim_buf_is_valid(buf) then
		return
	end
	if not eligible(win, buf) then
		clear_inherited_flash(win)
		return
	end
	stop(win)
	if not define_highlights() then
		return
	end

	local state = {
		timer = vim.uv.new_timer(),
		original_target = cursorline_target(vim.wo[win].winhighlight),
		cursorline = vim.wo[win].cursorline,
		cursorlineopt = vim.wo[win].cursorlineopt,
		step = 1,
	}
	timers[win] = state
	vim.wo[win].cursorline = true
	vim.wo[win].cursorlineopt = "both"
	vim.wo[win].winhighlight = set_cursorline_target(vim.wo[win].winhighlight, group_prefix .. "1")

	state.timer:start(
		math.floor(duration_ms / steps),
		math.floor(duration_ms / steps),
		vim.schedule_wrap(function()
			if timers[win] ~= state or not vim.api.nvim_win_is_valid(win) then
				stop(win)
				return
			end
			state.step = state.step + 1
			if state.step > steps then
				stop(win)
				return
			end
			local current = vim.wo[win].winhighlight
			local target = cursorline_target(current)
			if not target or not vim.startswith(target, group_prefix) then
				stop(win)
				return
			end
			vim.wo[win].winhighlight = set_cursorline_target(current, group_prefix .. state.step)
		end)
	)
end

function M.setup()
	define_highlights()
	local group = vim.api.nvim_create_augroup("CursorLineFocusFlash", { clear = true })
	vim.api.nvim_create_autocmd("ColorScheme", {
		group = group,
		callback = define_highlights,
	})
	vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, {
		group = group,
		callback = function(args)
			local win = vim.api.nvim_get_current_win()
			local buf = args.buf
			if win == last_win and buf == last_buf then
				return
			end
			local had_focus = last_win ~= nil
			last_win, last_buf = win, buf
			if had_focus then
				vim.schedule(function()
					flash(win, buf)
				end)
			end
		end,
	})
end

return M
