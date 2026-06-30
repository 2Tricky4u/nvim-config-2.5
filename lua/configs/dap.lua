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
-- Before launching: run openocd -f interface/stlink.cfg -f target/stm32f4x.cfg
dap.configurations.c = {
  {
    name = "STM32 via OpenOCD",
    type = "cppdbg",
    request = "launch",
    program = function()
      return vim.fn.input("ELF: ", vim.fn.getcwd() .. "/build/", "file")
    end,
    cwd = "${workspaceFolder}",
    stopAtEntry = true,
    miDebuggerPath = "arm-none-eabi-gdb",
    miDebuggerServerAddress = "localhost:3333",
    setupCommands = {
      { text = "-enable-pretty-printing", ignoreFailures = true },
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
