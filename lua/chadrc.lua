-- This file needs to have same structure as nvconfig.lua 
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :( 

---@type ChadrcConfig
local M = {}

M.base46 = {
  theme = "eldritch",
  transparency = true,

  -- treesitter-context has no base46 integration; give the sticky lines a
  -- real background (transparency would leave them see-through) and an
  -- underline marking where the pinned block ends.
  hl_add = {
    TreesitterContext = { bg = "one_bg" },
    TreesitterContextLineNumber = { fg = "light_grey", bg = "one_bg" },
    TreesitterContextBottom = { underline = true, sp = "grey" },
    TreesitterContextLineNumberBottom = { underline = true, sp = "grey" },
  },

  -- hl_override = {
  -- 	Comment = { italic = true },
  -- 	["@comment"] = { italic = true },
  -- },
}

-- M.nvdash = { load_on_startup = true }
-- M.ui = {
--       tabufline = {
--          lazyload = false
--      }
-- }

return M
