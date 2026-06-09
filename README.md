# nvim_harbor

A lightweight, asynchronous, and responsive **Telescope** extension to manage your `docker compose` services directly inside Neovim.

**nvim_harbor** streamlines your containerized development loop. Instead of context-switching to a separate terminal to view logs, drop into a container shell, or restart a broken service, you can do it all from a split-pane Telescope interface. 

---

## Features

* **Zero Configuration:** Automatically discovers services using native `docker compose config`.
* **Asynchronous Telemetry:** Fetches live states, mapped ports, and performance specs (CPU, memory, and I/O) on background threads without locking or freezing the Neovim UI.
* **Smart UI Layout:** Uses a compact horizontal layout split optimized for side-by-side service filtering and dashboard monitoring.
* **Native Split Terminals:** Interactive workflows—like tailing logs or spinning up container shells—automatically map straight into native, focusable Neovim terminal splits.

---

## Requirements

* Neovim `0.9.0`+
* [Telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
* [Plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
* Docker & Docker Compose V2 running on your system

---

## Installation

Add the plugin to your configuration using your preferred package manager.

### Using [lazy.nvim](https://github.com/folke/lazy.nvim) / LazyVim

Create a new file under `lua/plugins/harbor.lua` and add the following:

```lua
return {
  "maiobarbero/nvim_harbor",
  dependencies = { 
    "nvim-telescope/telescope.nvim", 
    "nvim-lua/plenary.nvim" 
  },
  cmd = {
    "HarborStart",
    "HarborStop",
    "HarborRebuild",
    "HarborDown",
    "HarborExec",
    "HarborLogs",
  },
  opts = {},
  config = function()
    require("harbor").setup()
  end,
}
```
## Usage & Commands
Run these commands inside any project directory that contains a valid docker-compose setup:

`:HarborStart`, Spin up a specific service,Background Job
`:HarborStop`, Stop a running service,Background Job
`:HarborRebuild`, "Force rebuild, recreate, and start a service",Background Job
`:HarborDown`, Instantly stop and remove container volumes,Background Job
`:HarborLogs`, Tail live logs for the service,Interactive Split Terminal
`:HarborExec`, Execute an interactive shell (bash or sh),Interactive Split Terminal

>[!Note] Background jobs utilize standard Neovim notifications to safely alert you with a Success or Failed toast message as soon as the Docker engine completes the instruction.

## Custom Keybindings
You can map the registered commands to your preferred hotkeys. Here is a recommended, leader-based layout:

### Standard Keymaps
Add this to your keymaps.lua or main configuration:
local map = vim.keymap.set
```lua
map("n", "<leader>hcu", "<cmd>HarborStart<CR>",   { desc = "Harbor: Start Container" })
map("n", "<leader>hcs", "<cmd>HarborStop<CR>",    { desc = "Harbor: Stop Container" })
map("n", "<leader>hcr", "<cmd>HarborRebuild<CR>", { desc = "Harbor: Rebuild Container" })
map("n", "<leader>hcd", "<cmd>HarborDown<CR>",    { desc = "Harbor: Remove Container" })
map("n", "<leader>hce", "<cmd>HarborExec<CR>",    { desc = "Harbor: Exec Container Shell" })
map("n", "<leader>hcl", "<cmd>HarborLogs<CR>",    { desc = "Harbor: Tail Logs" })
```

### Lazy-Loaded Keymaps
If you are using lazy.nvim, you can integrate the shortcuts cleanly right into the plugin configuration definition:
```lua
return {
  "maiobarbero/nvim_harbor",
  dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" },
  keys = {
    { "<leader>hcu", "<cmd>HarborStart<CR>",   desc = "Harbor: Start Container" },
    { "<leader>hcs", "<cmd>HarborStop<CR>",    desc = "Harbor: Stop Container" },
    { "<leader>hcr", "<cmd>HarborRebuild<CR>", desc = "Harbor: Rebuild Container" },
    { "<leader>hcd", "<cmd>HarborDown<CR>",    desc = "Harbor: Remove Container" },
    { "<leader>hce", "<cmd>HarborExec<CR>",    desc = "Harbor: Exec Container Shell" },
    { "<leader>hcl", "<cmd>HarborLogs<CR>",    desc = "Harbor: Tail Logs" },
  },
  config = function()
    require("harbor").setup()
  end,
}
```
