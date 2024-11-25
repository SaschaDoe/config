return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    filesystem = {
      filtered_items = {
        visible = true,
        hide_dotfiles = false,
        hide_gitignored = false,
      },
    },
  },
  keys = {
    {
      "<leader>E",
      function()
        require("neo-tree.command").execute({
          toggle = true,
          position = "float",
        })
      end,
      desc = "Toggle Explorer (floating)",
    },
    {
      "<leader>e",
      function()
        require("neo-tree.command").execute({
          toggle = true,
          position = "left",
        })
      end,
      desc = "Toggle Explorer",
    },
  },
}
