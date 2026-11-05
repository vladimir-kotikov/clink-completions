-- Use the installed CLI's Cobra protocol for commands, flags, board IDs,
-- libraries and config keys instead of maintaining a version-specific tree.
-- Load at startup so the generator can set word boundaries on the first Tab.
require('cobra').register('arduino-cli')
