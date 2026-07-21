local dap = require "dap"
local dapui = require "dapui"

-- ── Visual: inline variable values while stepping ───────────────────────────
require("nvim-dap-virtual-text").setup {
  commented = true,       -- render as a trailing comment
  virt_text_pos = "eol",  -- values at end of line
}

-- ── Gutter signs ────────────────────────────────────────────────────────────
local sign = vim.fn.sign_define
sign("DapBreakpoint",          { text = "●", texthl = "DiagnosticError" })
sign("DapBreakpointCondition", { text = "◆", texthl = "DiagnosticWarn" })
sign("DapLogPoint",            { text = "◆", texthl = "DiagnosticInfo" })
sign("DapBreakpointRejected",  { text = "○", texthl = "DiagnosticError" })
sign("DapStopped",             { text = "▶", texthl = "DiagnosticOk", linehl = "Visual", numhl = "DiagnosticOk" })

-- ── dap-ui: embedded-friendly layout ────────────────────────────────────────
dapui.setup {
  icons = { expanded = "▾", collapsed = "▸", current_frame = "▸" },
  layouts = {
    {
      position = "left",
      size = 44,
      elements = {
        { id = "scopes",      size = 0.40 }, -- locals + registers
        { id = "watches",     size = 0.24 },
        { id = "stacks",      size = 0.20 }, -- call stack
        { id = "breakpoints", size = 0.16 },
      },
    },
    {
      position = "bottom",
      size = 12,
      elements = {
        { id = "repl",    size = 0.55 }, -- type gdb/OpenOCD commands here
        { id = "console", size = 0.45 }, -- target stdout (semihosting)
      },
    },
  },
  controls = { enabled = true }, -- play/step/stop buttons in the REPL winbar
}

-- Auto-open/close the UI alongside debug sessions
dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open() end
dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
dap.listeners.before.event_exited["dapui_config"] = function() dapui.close() end

-- ── Keymaps ─────────────────────────────────────────────────────────────────
local map = vim.keymap.set
map("n", "<leader>db", dap.toggle_breakpoint, { desc = "DAP: toggle breakpoint" })
map("n", "<leader>dB", function() dap.set_breakpoint(vim.fn.input "Condition: ") end,
  { desc = "DAP: conditional breakpoint" })
map("n", "<leader>dc", dap.continue,      { desc = "DAP: continue / start" })
map("n", "<leader>di", dap.step_into,     { desc = "DAP: step into" })
map("n", "<leader>do", dap.step_over,     { desc = "DAP: step over" })
map("n", "<leader>dO", dap.step_out,      { desc = "DAP: step out" })
map("n", "<leader>dr", dap.repl.open,     { desc = "DAP: open REPL" })
map("n", "<leader>dR", dap.run_to_cursor, { desc = "DAP: run to cursor" })
map("n", "<leader>du", dapui.toggle,      { desc = "DAP: toggle UI" })
map("n", "<leader>dt", dap.terminate,     { desc = "DAP: terminate" })
map({ "n", "v" }, "<leader>dh", function() require("dap.ui.widgets").hover() end,
  { desc = "DAP: hover value under cursor" })
map({ "n", "v" }, "<leader>de", function() dapui.eval() end, { desc = "DAP: eval (cword/selection)" })
map("n", "<leader>dw", function() local w = require "dap.ui.widgets"; w.centered_float(w.scopes) end,
  { desc = "DAP: scopes float" })
map("n", "<leader>df", function() local w = require "dap.ui.widgets"; w.centered_float(w.frames) end,
  { desc = "DAP: frames float" })

-- ── Peripheral / memory peek via OpenOCD (works while halted) ────────────────
--   :Mem 0x40020414       read one word (GPIOB_ODR)
--   :Mem 0x40020400 6     read 6 words from the GPIOB base
vim.api.nvim_create_user_command("Mem", function(o)
  dap.repl.execute("monitor mdw " .. o.args)
end, { nargs = "+", desc = "OpenOCD: read memory word(s) while halted" })

-- ── SVD peripheral register decode (PyCortexMDebug, in the gdb REPL) ─────────
-- Use during an active, halted STM32 session:
--   :Svd             list all peripherals
--   :Svd GPIOB       decode every register of GPIOB (name, value, bitfields)
--   :Svd RCC AHB1ENR decode a single register
local SVD_SCRIPT = vim.fn.expand
  "~/.local/share/gdb-svd/venv/lib/python3.14/site-packages/cmdebug/svd_gdb.py"
local SVD_FILE = vim.fn.expand "~/.local/share/gdb-svd/STM32F429.svd"
local svd_loaded = false
vim.api.nvim_create_user_command("Svd", function(o)
  if not svd_loaded then
    dap.repl.execute("source " .. SVD_SCRIPT)
    dap.repl.execute("svd_load " .. SVD_FILE)
    svd_loaded = true
  end
  dap.repl.execute("svd " .. o.args)
end, { nargs = "*", desc = "STM32 peripheral registers by name (during a debug session)" })
-- Fresh gdb per session -> reload the SVD script the first time :Svd is used again
dap.listeners.after.event_initialized["svd_reset"] = function() svd_loaded = false end

-- ── RTT live log console ────────────────────────────────────────────────────
-- Opens a terminal split streaming RTT channel 0. Standalone (starts its own
-- OpenOCD), so use it when NOT in a debug session. Firmware must include rtt.c.
vim.api.nvim_create_user_command("Rtt", function()
  vim.cmd("botright 15split | terminal " .. vim.fn.expand "~/.local/bin/stm32-rtt")
  vim.cmd "startinsert"
end, { desc = "STM32: live RTT log console (standalone)" })

-- ── Adapters ────────────────────────────────────────────────────────────────
-- cpptools: Microsoft C/C++ adapter (connects to the OpenOCD GDB server)
dap.adapters.cppdbg = {
  type = "executable",
  command = vim.fn.stdpath "data" .. "/mason/bin/OpenDebugAD7",
}
-- Self-heal: OpenDebugAD7 needs an engine file named after the DAP client
-- ("nvim-dap.ad7Engine.json"), but mason only ships cppdbg.ad7Engine.json.
-- Without it the adapter crashes on launch. Recreate it if a cpptools update removed it.
do
  local bin = vim.fn.stdpath "data" .. "/mason/packages/cpptools/extension/debugAdapters/bin"
  if vim.fn.filereadable(bin .. "/nvim-dap.ad7Engine.json") == 0
    and vim.fn.filereadable(bin .. "/cppdbg.ad7Engine.json") == 1 then
    vim.fn.system { "cp", bin .. "/cppdbg.ad7Engine.json", bin .. "/nvim-dap.ad7Engine.json" }
  end
end
-- codelldb: LLDB-based adapter for native C/C++ and Rust (used by rustaceanvim too)
dap.adapters.codelldb = {
  type = "server",
  port = "${port}",
  executable = {
    command = vim.fn.stdpath "data" .. "/mason/bin/codelldb",
    args = { "--port", "${port}" },
  },
}

-- ── STM32 debug: nvim owns OpenOCD, then cppdbg connects to it ───────────────
-- cpptools' own debugServerPath auto-launch is unreliable under nvim-dap, so we
-- start OpenOCD ourselves, wait for its "Listening on port 3333" line, then run
-- the connect-only cppdbg config, and stop OpenOCD when the session ends.
-- Change the board cfg for another STM32 family (ls /usr/share/openocd/scripts/board/).
local OPENOCD_BOARD_CFG = "board/st_nucleo_f4.cfg"
local GDB = vim.fn.expand "~/.local/bin/arm-none-eabi-gdb-nx"

local stm32_config = {
  name = "STM32: flash + debug (OpenOCD)",
  type = "cppdbg",
  request = "launch",
  -- `program` (the ELF) is resolved and injected by stm32_debug() below
  cwd = "${workspaceFolder}",
  stopAtEntry = true,
  MIMode = "gdb",
  miDebuggerPath = GDB,
  miDebuggerServerAddress = "localhost:3333", -- connect to the OpenOCD we start below
  setupCommands = {
    { text = "-enable-pretty-printing", ignoreFailures = true },
  },
  -- These need the OpenOCD connection to exist, so they must run AFTER connect
  -- (running `load`/`monitor` in setupCommands fails pre-connection and aborts).
  postRemoteConnectCommands = {
    { text = '-interpreter-exec console "monitor reset halt"', ignoreFailures = true },
    { text = '-interpreter-exec console "monitor arm semihosting enable"', ignoreFailures = true },
    { text = '-interpreter-exec console "load"', ignoreFailures = false },
    { text = '-interpreter-exec console "monitor reset halt"', ignoreFailures = true },
  },
}

-- OpenOCD lifecycle
local openocd_job = nil
local function stop_openocd()
  if openocd_job then vim.fn.jobstop(openocd_job); openocd_job = nil end
  -- also clear any stray OpenOCD (failed attempt, or one started by hand) that
  -- would keep holding the ST-Link and block a fresh connection
  vim.fn.system { "pkill", "-x", "openocd" }
end

-- Find the ELF to debug: auto-detect build/*.elf; prompt only if none/ambiguous.
local function resolve_elf()
  local cwd = vim.fn.getcwd()
  local elfs = vim.fn.glob(cwd .. "/build/*.elf", false, true)
  local elf = (#elfs == 1) and elfs[1]
    or vim.fn.input("ELF: ", elfs[1] or (cwd .. "/build/"), "file")
  if elf == "" or vim.fn.filereadable(elf) == 0 then
    vim.notify("No ELF to debug. Run :CMakeBuild first (expected build/blink.elf).",
      vim.log.levels.ERROR)
    return nil
  end
  return elf
end

local function stm32_debug()
  local elf = resolve_elf()
  if not elf then return end
  stop_openocd() -- clear any previous/stray instance
  vim.wait(300) -- let the USB probe settle after killing a stray OpenOCD
  local cfg = vim.tbl_extend("force", stm32_config, { program = elf })
  local started = false
  openocd_job = vim.fn.jobstart({ "openocd", "-f", OPENOCD_BOARD_CFG }, {
    on_stderr = function(_, data) -- OpenOCD logs to stderr
      if started then return end
      for _, line in ipairs(data or {}) do
        if line:find "Listening on port 3333" then
          started = true
          vim.schedule(function() dap.run(cfg) end) -- server up → connect
          return
        end
      end
    end,
    on_exit = function(_, code)
      openocd_job = nil
      if not started then
        vim.schedule(function()
          vim.notify(
            "OpenOCD exited before it was ready (code " .. code .. ").\n"
              .. "Board plugged into the USB PWR port? Probe free (no :Rtt running)?",
            vim.log.levels.ERROR
          )
        end)
      end
    end,
  })
  if openocd_job <= 0 then
    vim.notify("Could not start OpenOCD — is it installed and on PATH?", vim.log.levels.ERROR)
  end
end

-- Entry points for embedded debugging (they start OpenOCD; don't use <leader>dc to start).
-- NB: <leader>dd is intentionally left to mappings.lua ("Run Python file").
vim.api.nvim_create_user_command("Stm32Debug", stm32_debug, { desc = "Flash + debug STM32 (starts OpenOCD)" })
map("n", "<leader>dF", stm32_debug, { desc = "DAP: flash + debug STM32 (OpenOCD)" })

-- Tear OpenOCD down when the debug session ends
dap.listeners.after.event_terminated["stm32_ocd"] = stop_openocd
dap.listeners.after.event_exited["stm32_ocd"] = stop_openocd

-- ── Build + flash to the board (no debugging) ───────────────────────────────
-- <F5> or :Flash — builds via the CMake `flash` target (which reflashes with
-- OpenOCD) in a terminal split. Refuses while a debug session owns the probe.
local function stm32_flash()
  if dap.session() then
    vim.notify("A debug session is active — stop it (<leader>dt) before flashing.", vim.log.levels.WARN)
    return
  end
  vim.fn.system { "pkill", "-x", "openocd" } -- free the probe if a stray OpenOCD holds it
  vim.cmd "botright 12split | terminal cmake --build build --target flash"
  vim.cmd "startinsert"
end
vim.api.nvim_create_user_command("Flash", stm32_flash, { desc = "Build + flash to board" })
map("n", "<F5>", stm32_flash, { desc = "Build + flash to board" })

-- <leader>dc picker (once a session is running, it just continues execution):
dap.configurations.c = {
  {
    name = "Native C (codelldb)",
    type = "codelldb",
    request = "launch",
    program = function()
      return vim.fn.input("Binary: ", vim.fn.getcwd() .. "/", "file")
    end,
    cwd = "${workspaceFolder}",
    stopOnEntry = false,
  },
}
dap.configurations.cpp = dap.configurations.c
