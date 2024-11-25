-- Set leader key to space
vim.g.mapleader = " "

-- Keymap function for convenience
local keymap = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true }

-- Function to select all text and restore cursor position
local function select_all_and_restore_cursor()
  -- Save current cursor position
  local current_pos = vim.api.nvim_win_get_cursor(0)
  -- Enter Visual Line mode and select all lines
  vim.cmd("normal! ggVG")
  -- Restore cursor position
  vim.api.nvim_win_set_cursor(0, current_pos)
end

-- Map Ctrl+A in Normal mode to the function
vim.keymap.set("n", "<C-a>", select_all_and_restore_cursor, opts)

-- Additional key mappings for enhanced navigation and editing

-- Insert mode: 'jk' to Normal mode
keymap("i", "jk", "<Esc>", opts)

--Scrolling
keymap("n", "<C-f>", "<C-d>zz", opts)
keymap("n", "<C-u>", "<C-u>zz", opts)

-- Normal mode: 'H' to move to the beginning of the line
keymap("n", "H", "^", opts)

-- Normal mode: 'L' to move to the end of the line
keymap("n", "L", "$", opts)

-- Normal mode: 'J' to join lines without spaces
keymap("n", "J", "gJ", opts)

-- Visual mode: '>' to indent and reselect
keymap("v", ">", ">gv", opts)

-- Visual mode: '<' to un-indent and reselect
keymap("v", "<", "<gv", opts)

-- Normal mode: 'Y' to yank to the end of the line
keymap("n", "Y", "y$", opts)

-- Normal mode: 'Q' to disable Ex mode
keymap("n", "Q", "<Nop>", opts)

-- Normal mode: 'n' and 'N' to center search results
keymap("n", "n", "nzzzv", opts)
keymap("n", "N", "Nzzzv", opts)

-- Normal mode: 'U' to redo
keymap("n", "U", "<C-r>", opts)

-- Custom Key Bindings
-- Visual mode: 'Ctrl+C' to copy
keymap("v", "<C-c>", '"+y', opts)

-- Normal and Visual mode: 'Ctrl+X' to cut
keymap("v", "<C-x>", '"+x', opts)
keymap("n", "<C-x>", '"+d', opts)

-- Insert mode: 'Ctrl+V' to paste
keymap("i", "<C-v>", "<C-r>+", opts)

-- Normal and Visual mode: 'Ctrl+V' to paste
keymap("v", "<C-v>", '"+p', opts)
keymap("n", "<C-v>", '"+p', opts)

-- Normal mode: 'Ctrl+D' to duplicate line
keymap("n", "<C-dd>", "yyp", opts)
