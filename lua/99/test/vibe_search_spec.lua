-- luacheck: globals describe it assert before_each after_each
local _99 = require("99")
local Window = require("99.window")
local ops = require("99.ops")
local test_utils = require("99.test.test_utils")
local eq = assert.are.same

describe("vibe_search", function()
  local provider
  local previous_capture_input
  local previous_capture_select_input
  local previous_vibe

  before_each(function()
    provider = test_utils.TestProvider.new()
    _99.setup(test_utils.get_test_setup_options({}, provider))

    previous_capture_input = Window.capture_input
    previous_capture_select_input = Window.capture_select_input
    previous_vibe = ops.vibe
  end)

  after_each(function()
    Window.capture_input = previous_capture_input
    Window.capture_select_input = previous_capture_select_input
    ops.vibe = previous_vibe
  end)

  it("selects a previous search and passes edited output to vibe", function()
    _99.search({
      additional_prompt = "find error handling",
    })
    provider:resolve("success", "/tmp/foo.lua:1:1,search note")
    test_utils.next_frame()

    local selected_content
    Window.capture_select_input = function(_, opts)
      opts.cb(true, opts.content[1])
    end

    Window.capture_input = function(_, opts)
      selected_content = opts.content
      opts.cb(true, "extra vibe context")
    end

    local vibe_prompt
    ops.vibe = function(_, opts)
      vibe_prompt = opts.additional_prompt
    end

    _99.vibe_search()

    eq({ "/tmp/foo.lua:1:1,search note" }, selected_content)
    eq("extra vibe context", vibe_prompt)
  end)
end)
