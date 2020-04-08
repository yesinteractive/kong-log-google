local BasePlugin = require "kong.plugins.base_plugin"
-- this codes just runs a simple echo function modeled from https://www.jerney.io/header-echo-kong-plugin/
-- another good source for plugin templating is https://github.com/Kong/kong-plugin

local myHandler = BasePlugin:extend()

myHandler.PRIORITY = 2000
myHandler.VERSION = "0.1.12"

function myHandler:new()
  myHandler.super.new(self, "plugin_echo-header")
  self.echo_string = ""
end

-- Run this when the client request hits the service
function myHandler:access(conf)
  myHandler.super.access(self)
  -- kong.* functions are from the PDK (plugin development kit)
  -- and do not need to be explicitly required
  if kong.request.get_header(conf.requestHeader) then self.echo_string = kong.request.get_header(conf.requestHeader) 
    else return kong.response.exit(500, "Missing Header")
  end
end



-- Run this when the response header has been received
-- from the upstream service
function myHandler:header_filter(conf)
  myHandler.super.header_filter(self)
  if self.echo_string ~= "" then
    kong.response.set_header(conf.responseHeader, self.echo_string)
  else
   
  end
end


function myHandler:body_filter(conf)

 -- return kong.response.exit(403, "Access Forbidden")

end





---------------------------------------------------------------------------------------------
-- In the code below, just remove the opening brackets; `[[` to enable a specific handler
--
-- The handlers are based on the OpenResty handlers, see the OpenResty docs for details
-- on when exactly they are invoked and what limitations each handler has.
---------------------------------------------------------------------------------------------

--[[ loading-config
starting-worker
rewrite
content
rewrite tail
access tail
output-header-filter
output-body-filter
log --]]

--[[ handles more initialization, but AFTER the worker process has been forked/created.
-- It runs in the 'init_worker_by_lua_block'
function plugin:init_worker()
  -- your custom code here
end --]]


--[[ runs in the ssl_certificate_by_lua_block handler
function plugin:certificate(plugin_conf)
  -- your custom code here
end --]]


--[[ runs in the 'rewrite_by_lua_block'
-- IMPORTANT: during the `rewrite` phase neither the `api` nor the `consumer` will have
-- been identified, hence this handler will only be executed if the plugin is
-- configured as a global plugin!
function plugin:rewrite(plugin_conf)
  -- your custom code here
end --]]


---[[ runs in the 'access_by_lua_block'
--function plugin:access(plugin_conf)

  -- your custom code here
--  ngx.req.set_header("Hello-World", "this is on a request")

--end --]]


---[[ runs in the 'header_filter_by_lua_block'
--function plugin:header_filter(plugin_conf)

  -- your custom code here, for example;
 -- ngx.header["Bye-World"] = "this is on the response"

--end --]]


--[[ runs in the 'body_filter_by_lua_block'
function plugin:body_filter(plugin_conf)
  -- your custom code here
end --]]


--[[ runs in the 'log_by_lua_block'
function plugin:log(plugin_conf)
  -- your custom code here
end --]]

return myHandler
