 local typedefs = require "kong.db.schema.typedefs"


return {
  name = "log-google",
  fields = {
    {
      -- this plugin will only be applied to Services or Routes
      consumer = typedefs.no_consumer
    },
    {
      -- this plugin will only run within Nginx HTTP module
      protocols = typedefs.protocols_http
    },
    {
      config = {
        type = "record",
        fields = {
          -- Describe your plugin's configuration's schema here.  
            { tid = { type = "string", default = "UA-somevalue", required = true, }, },
            { cid = { type = "string", default = "555", required = true, }, },
      },
    },
  },
 },
}