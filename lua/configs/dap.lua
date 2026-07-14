local dap = require "dap"
local dapui = require "dapui"

dapui.setup()

-- Auto-open/close the UI alongside debug sessions
dap.listeners.after.event_initialized["dapui_config"] = function()
  dapui.open()
end
dap.listeners.before.event_terminated["dapui_config"] = function()
  dapui.close()
end
dap.listeners.before.event_exited["dapui_config"] = function()
  dapui.close()
end

local map = vim.keymap.set
map("n", "<leader>db", dap.toggle_breakpoint, { desc = "DAP: toggle breakpoint" })
map("n", "<leader>dc", dap.continue, { desc = "DAP: continue" })
map("n", "<leader>di", dap.step_into, { desc = "DAP: step into" })
map("n", "<leader>do", dap.step_over, { desc = "DAP: step over" })
map("n", "<leader>dO", dap.step_out, { desc = "DAP: step out" })
map("n", "<leader>dr", dap.repl.open, { desc = "DAP: open REPL" })
map("n", "<leader>du", dapui.toggle, { desc = "DAP: toggle UI" })
map("n", "<leader>dt", dap.terminate, { desc = "DAP: terminate" })

-- ── Adapters ───────────────────────────────────────────────────────────────

-- cpptools: Microsoft C/C++ adapter (connects to OpenOCD GDB server for STM32)
dap.adapters.cppdbg = {
  type = "executable",
  command = vim.fn.stdpath "data" .. "/mason/bin/OpenDebugAD7",
}

-- codelldb: LLDB-based adapter for native C/C++ and Rust (used by rustaceanvim too)
dap.adapters.codelldb = {
  type = "server",
  port = "${port}",
  executable = {
    command = vim.fn.stdpath "data" .. "/mason/bin/codelldb",
    args = { "--port", "${port}" },
  },
}

-- ── STM32 debug configurations ─────────────────────────────────────────────
-- No separate terminal needed: cpptools launches OpenOCD, waits for the GDB port,
-- flashes the ELF (`load`), halts at main. Change the board cfg below for another
-- STM32 family (see: ls /usr/share/openocd/scripts/board/).
local OPENOCD_BOARD_CFG = "board/st_nucleo_f4.cfg"
dap.configurations.c = {
  {
    name = "STM32: flash + debug (OpenOCD)",
    type = "cppdbg",
    request = "launch",
    program = function()
      return vim.fn.input("ELF: ", vim.fn.getcwd() .. "/build/", "file")
    end,
    cwd = "${workspaceFolder}",
    stopAtEntry = true,
    MIMode = "gdb",
    miDebuggerPath = "arm-none-eabi-gdb",
    miDebuggerServerAddress = "localhost:3333",
    -- Let cpptools start and own the GDB server:
    debugServerPath = "openocd",
    debugServerArgs = "-f " .. OPENOCD_BOARD_CFG,
    filterStderr = true,
    serverStarted = "Listening on port 3333 for gdb connections",
    setupCommands = {
      { text = "-enable-pretty-printing", ignoreFailures = true },
      { text = '-interpreter-exec console "monitor reset halt"', ignoreFailures = true },
      { text = '-interpreter-exec console "load"', ignoreFailures = false },
      { text = '-interpreter-exec console "monitor reset halt"', ignoreFailures = true },
    },
  },
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
