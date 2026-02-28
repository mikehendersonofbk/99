local make_prompt = require("99.ops.make-prompt")
local CleanUp = require("99.ops.clean-up")
local Window = require("99.window")

local make_clean_up = CleanUp.make_clean_up
local make_observer = CleanUp.make_observer

--- @param context _99.Prompt
--- @param response string
local function finish_chat(context, response)
  context.data = {
    type = "vibe",
    response = response,
    qfix_items = {},
  }
  Window.create_split(vim.split(response, "
"), nil, { filetype = "markdown" })
end

--- @param context _99.Prompt
--- @param opts _99.ops.Opts
local function chat(context, opts)
  opts = opts or {}

  local logger = context.logger:set_area("chat")
  logger:debug("chat", "with opts", opts.additional_prompt)

  local clean_up = make_clean_up(function()
    context:stop()
  end)

  local prompt, refs =
    make_prompt(context, context._99.prompts.prompts.chat(), opts)

  context:add_prompt_content(prompt)
  context:add_references(refs)
  context:add_clean_up(clean_up)

  context:start_request(make_observer(clean_up, function(status, response)
    if status == "cancelled" then
      logger:debug("request cancelled for chat")
    elseif status == "failed" then
      logger:error(
        "request failed for chat",
        "error response",
        response or "no response provided"
      )
    elseif status == "success" then
      finish_chat(context, response)
    end
  end))
end

return chat
