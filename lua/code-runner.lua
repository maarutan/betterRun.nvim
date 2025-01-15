local M = {}
local uv = vim.loop

-- Default configurations
M.defaults = {
	keymap = "<A-S-r>",
	interrupt_keymap = "<F2>",
	terminal_mode = "float", -- Default terminal mode
	commands = {
		python = "python3 -u $dir/$fileName",
		lua = "lua $dir/$fileName",
		javascript = "node $dir/$fileName",
		typescript = "ts-node $dir/$fileName",
		ruby = "ruby $dir/$fileName",
		go = "go run $dir/$fileName",
		java = "java $fileName", -- Assuming compiled separately
		cpp = "g++ -o $dir/output $dir/$fileName && $dir/output",
	},
	extensions = {
		python = { "py" },
		lua = { "lua" },
		javascript = { "js" },
		typescript = { "ts" },
		ruby = { "rb" },
		go = { "go" },
		java = { "java" },
		cpp = { "cpp" },
	},
	debug = false, -- Debug mode flag
}
M.config = {}
M.lock = false
M.previous_keybinds = {}

-- Debug logging function
local function log_debug(message)
	if M.config.debug then
		vim.notify("[CodeRunner DEBUG] " .. message, vim.log.levels.INFO)
	end
end

-- Utility function to merge tables
local function merge_tables(default, user)
	if not user then
		return default
	end
	for k, v in pairs(user) do
		if type(v) == "table" and type(default[k]) == "table" then
			default[k] = merge_tables(default[k], v)
		else
			default[k] = v
		end
	end
	return default
end

-- Determine terminal direction dynamically
local function determine_direction()
	local width = vim.o.columns
	local height = vim.o.lines

	if width > 120 then
		return "vertical"
	elseif height > 40 then
		return "horizontal"
	else
		return "float"
	end
end

-- Generate command
function M.generate_command(command_template)
	local bufnr = vim.api.nvim_get_current_buf()
	local file_path = vim.api.nvim_buf_get_name(bufnr)
	local file_dir = vim.fn.fnamemodify(file_path, ":h")
	local file_name = vim.fn.fnamemodify(file_path, ":t")
	local file_name_without_ext = vim.fn.fnamemodify(file_path, ":t:r")
	local file_extension = vim.fn.fnamemodify(file_path, ":e")

	local cmd = command_template
		:gsub("$dir", file_dir)
		:gsub("$fileName", file_name)
		:gsub("$fileNameWithoutExt", file_name_without_ext)
		:gsub("$fileExtension", file_extension)
		:gsub("$filePath", file_path)

	return cmd
end

-- Run the command
function M.run_command(cmd)
	if M.lock then
		vim.notify("CodeRunner is busy. Please wait...", vim.log.levels.WARN)
		return
	end

	M.lock = true

	local term = nil
	for _, t in pairs(require("toggleterm.terminal").get_all()) do
		if t.id == 1 then
			term = t
			break
		end
	end

	if not term then
		local direction = M.config.terminal_mode == "auto" and determine_direction() or M.config.terminal_mode
		term = require("toggleterm.terminal").Terminal:new({
			id = 1,
			direction = direction,
			close_on_exit = false, -- Keep terminal open after execution
		})
		term:open() -- Open the new terminal
		log_debug("Created and opened new terminal.")
	elseif not term:is_open() then
		term:open() -- Open the existing terminal if it's not already open
		log_debug("Opened existing terminal.")
	else
		log_debug("Using already open terminal.")
	end

	term:send(cmd, true) -- Send the command

	vim.defer_fn(function()
		if not term:is_open() then
			term:open() -- Ensure terminal is focused only if needed
		end
		vim.api.nvim_set_current_win(term.window) -- Focus the terminal window
		vim.api.nvim_feedkeys("i", "n", false) -- Switch to insert mode
	end, 100)

	if M.config.debug then
		vim.notify("Running: " .. cmd, vim.log.levels.INFO)
	end

	vim.defer_fn(function()
		M.lock = false
	end, 1000)
end

-- Run the code
function M.run()
	log_debug("Run function called")
	local cmd = nil

	log_debug("Falling back to language default command")
	local bufnr = vim.api.nvim_get_current_buf()
	local file_path = vim.api.nvim_buf_get_name(bufnr)
	if file_path == "" then
		vim.notify("No file is currently open.", vim.log.levels.WARN)
		return
	end

	local file_extension = vim.fn.fnamemodify(file_path, ":e")
	local language = nil

	for lang, exts in pairs(M.config.extensions) do
		for _, ext in ipairs(exts) do
			if ext == file_extension then
				language = lang
				break
			end
		end
		if language then
			break
		end
	end

	if not language then
		vim.notify("Unsupported file extension: " .. file_extension, vim.log.levels.ERROR)
		return
	end

	local command = M.config.commands[language]
	if not command then
		vim.notify("No command configured for language: " .. language, vim.log.levels.ERROR)
		return
	end

	cmd = M.generate_command(command)
	M.run_command(cmd)
end

-- Interrupt the running command
function M.send_interrupt()
	local term = nil
	for _, t in pairs(require("toggleterm.terminal").get_all()) do
		if t.id == 1 then
			term = t
			break
		end
	end

	if term then
		term:send("<C-c>", false) -- Send Ctrl+C
		vim.notify("Interrupt signal sent.", vim.log.levels.INFO)
	else
		vim.notify("No active terminal to interrupt.", vim.log.levels.WARN)
	end
end

-- Set up keybindings
function M.set_keymaps()
	-- Unbind previous keymaps if they exist
	if M.previous_keybinds and next(M.previous_keybinds) then
		for _, keybind in ipairs(M.previous_keybinds) do
			if vim.fn.maparg(keybind, "n") ~= "" then
				vim.api.nvim_del_keymap("n", keybind)
				log_debug("Unbound previous keybind: " .. keybind)
			end
		end
	end

	M.previous_keybinds = {}

	-- Bind the run key
	vim.api.nvim_set_keymap(
		"n",
		M.config.keymap,
		"<Cmd>lua require('code-runner').run()<CR>",
		{ noremap = true, silent = true }
	)
	table.insert(M.previous_keybinds, M.config.keymap)

	-- Bind the interrupt key
	vim.api.nvim_set_keymap(
		"n",
		M.config.interrupt_keymap,
		"<Cmd>lua require('code-runner').send_interrupt()<CR>",
		{ noremap = true, silent = true }
	)
	table.insert(M.previous_keybinds, M.config.interrupt_keymap)
end

-- Setup function
function M.setup(user_opts)
	M.defaults = merge_tables(M.defaults, user_opts)
	M.config = vim.deepcopy(M.defaults)
	M.set_keymaps()
end

return M
