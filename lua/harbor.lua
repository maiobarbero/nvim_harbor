local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previewers = require("telescope.previewers")

local M = {}

local function get_compose_services()
	local obj = vim.system({ "docker", "compose", "config", "--services" }, { text = true }):wait()
	if obj.code ~= 0 then
		vim.notify("No docker compose or Docker is not running.", vim.log.levels.WARN)
	end

	local services = {}
	for s in obj.stdout:gmatch("[^\r\n]+") do
		table.insert(services, s)
	end
	return services
end

local function create_docker_previewer()
	return previewers.new_buffer_previewer({
		title = "Container Live Metrics",
		define_preview = function(self, entry)
			local service = entry.value
			local bufnr = self.state.bufnr

			vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { " Fetching metrics for [" .. service .. "]..." })

			vim.system({ "docker", "compose", "ps", "--format", "{{.State}}|{{.Ports}}", service }, { text = true }, function(ps_obj)

				vim.system({ "docker", "compose", "stats", "--no-stream", "--format", "{{.CPUPerc}}|{{.MemUsage}}|{{.MemPerc}}|{{.NetIO}}|{{.BlockIO}}", service }, { text = true }, function(img_obj)

					vim.schedule(function()
						if not vim.api.nvim_buf_is_valid(bufnr) then
							return
						end

						local lines = {
							" # " .. service:upper(),
							" " .. string.rep("━", #service + 3),
							"",
							" ## State & Ports",
						}

						if ps_obj.code == 0 and ps_obj.stdout ~= "" then
							for line in ps_obj.stdout:gmatch("[^\r\n]+") do
								table.insert(lines, "    " .. line)
							end
						else
							table.insert(lines, "    ❌ Container is currently stopped or uncreated.")
						end

						table.insert(lines, "")
						table.insert(lines, " ## Performance stats (CPU / MEM / IO)")

						if img_obj.code == 0 and img_obj.stdout ~= "" then
							for line in img_obj.stdout:gmatch("[^\r\n]+") do
								table.insert(lines, "    " .. line)
							end
						else
							table.insert(lines, "    ⚠️ No details found.")
						end

						-- Inject lines into the preview buffer and apply Markdown syntax highlighting
						vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
						vim.api.nvim_set_option_value("filetype", "markdown", { buf = bufnr })
					end)
				end)
			end)
		end,
	})
end

local function execute_command(prompt_title, command_template, is_interactive)
	local services = get_compose_services()
	if #services == 0 then
		return
	end

	pickers
		.new({}, {
			prompt_title = prompt_title,

			layout_strategy = "horizontal",
			layout_config = {
				width = 0.70,
				height = 0.70,
				preview_width = 0.7,
			},

			finder = finders.new_table({
				results = services,
			}),
			sorters = conf.generic_sorter({}),
			previewer = create_docker_previewer(),
			attach_mappings = function(prompt_bufnr)
				actions.select_default:replace(function()
					actions.close(prompt_bufnr)
					local selection = action_state.get_selected_entry()
					local service = selection[1]

					local cmd = string.gsub(command_template, "%%s", service)

					if is_interactive then
						-- For logs and exec, open a Neovim terminal in a split
						vim.cmd("vsplit | terminal " .. cmd)
					else
						-- For silent background tasks (start, stop, etc)
						vim.notify("Running: " .. cmd, vim.log.levels.INFO)
						vim.fn.jobstart(cmd, {
							on_exit = function(_, code)
								if code == 0 then
									vim.notify("Success: " .. cmd, vim.log.levels.INFO)
								else
									vim.notify("Failed: " .. cmd, vim.log.levels.ERROR)
								end
							end,
						})
					end
				end)
				return true
			end,
		})
		:find()
end

function M.setup()
	vim.api.nvim_create_user_command("HarborStart", function()
		execute_command("Start Service", "docker compose up -d %s", false)
	end, {})

	-- Stop a service
	vim.api.nvim_create_user_command("HarborStop", function()
		execute_command("Stop Service", "docker compose stop %s", false)
	end, {})

	-- Force rebuild and recreate a service
	vim.api.nvim_create_user_command("HarborRebuild", function()
		execute_command("Rebuild Service", "docker compose up -d --build --force-recreate %s", false)
	end, {})

	-- Remove a specific service (since 'down' is usually stack-wide)
	vim.api.nvim_create_user_command("HarborDown", function()
		execute_command("Remove Service", "docker compose rm -s -v -f %s", false)
	end, {})

	-- Execute a shell in the container (Interactive)
	vim.api.nvim_create_user_command("HarborExec", function()
		-- Defaults to bash, falls back to sh if bash isn't present in Alpine
		execute_command("Exec Service", "docker compose exec %s /bin/sh -c 'bash || sh'", true)
	end, {})

	-- Tail logs (Interactive)
	vim.api.nvim_create_user_command("HarborLogs", function()
		execute_command("Tail Logs", "docker compose logs -f %s", true)
	end, {})
end

return M
