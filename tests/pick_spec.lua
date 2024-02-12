local utils = require("tests.utils")

local Buffer = utils.MockBuffer

--- NOTE: The pinned group is group 1 and so all groups must appear after this
--- all group are moved down by one because of this
describe("Group tests - ", function()
  local groups ---@module "bufferline.groups"
  local state ---@module "bufferline.state"
  local config ---@module "bufferline.config"
  local bufferline ---@module "bufferline"
  local pick = require"bufferline.pick"
  pick.write_buffer_sets = function () end
  local cwd1 = vim.loop.cwd() .. "/a"
  local cwd2 = vim.loop.cwd() .. "/b"

  before_each(function()
    pick.buffer_sets = {}
  end)

  it("should sort components by groups", function()
    groups.setup({
      options = {
        groups = {
          items = {
            {
              name = "test-group",
              matcher = function(buf) return buf.name:match("dummy") end,
            },
          },
        },
      },
    })
    local components = vim.tbl_map(set_buf_group, {
      Buffer:new({ name = "dummy-1.txt" }),
      Buffer:new({ name = "dummy-2.txt" }),
      Buffer:new({ name = "file-2.txt" }),
    })
    local sorted, components_by_group = groups.sort_by_groups(components)
    assert.is_equal(#sorted, 3)
    assert.equal(sorted[1]:as_element().name, "dummy-1.txt")
    assert.equal(sorted[#sorted]:as_element().name, "file-2.txt")

    assert.is_equal(vim.tbl_count(components_by_group), 3)
  end)

  it("should add group markers", function()
    local conf = {
      highlights = {},
      options = {
        groups = {
          items = {
            {
              name = "test-group",
              matcher = function(buf) return buf.name:match("dummy") end,
            },
          },
        },
      },
    }
    bufferline.setup(conf)
    local components = {
      Buffer:new({ name = "dummy-1.txt" }),
      Buffer:new({ name = "dummy-2.txt" }),
      Buffer:new({ name = "file-2.txt" }),
    }
    components = vim.tbl_map(set_buf_group, components)
    components = groups.render(components, function(t) return t end)
    assert.equal(5, #components)
    local g_start = components[1]
    local g_end = components[4]
    assert.is_equal(g_start.type, "group_start")
    assert.is_equal(g_end.type, "group_end")
    local component = g_start.component()
    assert.is_true(utils.find_text(component, "test-group"))
  end)

  it("should sort each group individually", function()
    local conf = {
      highlights = {},
      options = {
        groups = {
          items = {
            {
              name = "A",
              matcher = function(buf) return buf.name:match("%.txt") end,
            },
            {
              name = "B",
              matcher = function(buf) return buf.name:match("%.js") end,
            },
            {
              name = "C",
              matcher = function(buf) return buf.name:match("%.dart") end,
            },
          },
        },
      },
    }
    bufferline.setup(conf)
    local components = {
      Buffer:new({ name = "a.txt" }),
      Buffer:new({ name = "b.txt" }),
      Buffer:new({ name = "d.dart" }),
      Buffer:new({ name = "c.dart" }),
      Buffer:new({ name = "h.js" }),
      Buffer:new({ name = "g.js" }),
    }
    components = vim.tbl_map(set_buf_group, components)
    components = groups.render(components, function(t)
      table.sort(t, function(a, b) return a:as_element().name > b:as_element().name end)
      return t
    end)
    assert.is_equal(components[2]:as_element().name, "b.txt")
    assert.is_equal(components[3]:as_element().name, "a.txt")
    assert.is_equal(components[6]:as_element().name, "h.js")
    assert.is_equal(components[7]:as_element().name, "g.js")
    assert.is_equal(components[10]:as_element().name, "d.dart")
    assert.is_equal(components[11]:as_element().name, "c.dart")
  end)

  it("should pin a buffer", function()
    bufferline.setup()
    vim.cmd("edit dummy-1.txt")
    nvim_bufferline()
    vim.cmd("BufferLineTogglePin")
    nvim_bufferline()
    local buf = utils.find_buffer("dummy-1.txt", state)
    local group = buf and groups.get_manual_group(buf)
    assert.is_truthy(group and group:match("pinned"))
  end)

  it("should unpin a pinned buffer", function()
    bufferline.setup()
    vim.cmd("edit dummy-1.txt")
    nvim_bufferline()
    vim.cmd("BufferLineTogglePin")
    nvim_bufferline()
    local buf = utils.find_buffer("dummy-1.txt", state)
    local group = buf and groups.get_manual_group(buf)
    assert.is_truthy(group and group:match("pinned"))
    vim.cmd("BufferLineTogglePin")
    nvim_bufferline()
    group = buf and groups.get_manual_group(buf)
    assert.is_falsy(group)
  end)

  it("pinning should override other groups", function()
    bufferline.setup({
      options = {
        groups = {
          items = {
            {
              name = "A",
              matcher = function(buf) return buf.name:match("%.txt") end,
            },
          },
        },
      },
    })
    vim.cmd("edit dummy-1.txt")
    nvim_bufferline()
    vim.cmd("BufferLineTogglePin")
    nvim_bufferline()
    local buf = utils.find_buffer("dummy-1.txt", state)
    local group = buf and groups.get_manual_group(buf)
    assert.is_truthy(group and group:match("pinned"))
  end)
end)
