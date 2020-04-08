return {
  no_consumer = true, -- This means our plugin will not apply to specific service consumers, if false will apply to consumers
  fields      = {
    requestHeader = {
      type     = "string",
      required = false,
      default  = "X-Request-Echo"
    },
    responseHeader = {
      type     = "string",
      required = false,
      default  = "X-Response-Echo"
    }
  }
}
