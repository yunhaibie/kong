-- handler.lua
local BasePlugin = require "kong.plugins.base_plugin"
local HelloWorldHandler = BasePlugin:extend()

local ngx_log = ngx.log
local DEBUG = ngx.DEBUG

HelloWorldHandler.PRIORITY = 3000

function HelloWorldHandler:new()
  HelloWorldHandler.super.new(self, "hello-world")
end

function HelloWorldHandler:access(conf)
  HelloWorldHandler.super.access(self)

  if conf.say_hello then
    ngx_log(DEBUG, "============ Hello World! ============")
    ngx.header["Hello-World"] = "=== Hello World ==="
  else
    ngx_log(DEBUG, "============ Bye World! ============")
    ngx.header["Hello-World"] = "=== Bye World ==="
  end

end

return HelloWorldHandler