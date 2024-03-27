-----------------------------------------------------------------------------
-- Tab completion for the Cloud Foundry CLI (cf) on Windows
-- for use with clink (https://github.com/mridgers/clink)
--
-- Copyright (c) 2017 Dies Koper
--
-- License: MIT, see https://opensource.org/licenses/MIT
-----------------------------------------------------------------------------

local parser = clink.arg.new_parser

-- execute cf with goflags env var to retrieve newline delimited completions
local function list_cf_completions()
   local cur_line = rl_state.line_buffer
   local exec_cmd = 'set GO_FLAGS_COMPLETION=1 && '..cur_line..' 2>nul'

   for candidate in io.popen(exec_cmd):lines() do
--      print('[m:'..candidate..']')

      -- goflags sometimes returns previous arg/opt, so detect and skip
      -- (coz space after last arg/opt is not propagated to goflags?)
      local i, _ = string.find(cur_line, candidate, -2 - #candidate, true)
      if not i then
         clink.add_match(candidate)
      end
   end

   return {}
end

local completions = function (token)   -- luacheck: no unused args
   return list_cf_completions()
end

-- 6 levels deep: e.g. `cf set-space-role user org space role -v`
local cf_parser = parser(
   {completions},
   {completions},
   {completions},
   {completions},
   {completions},
   {completions}
)

clink.arg.register_parser("cf", cf_parser)
