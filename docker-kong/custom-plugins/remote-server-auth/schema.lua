local typedefs = require "kong.db.schema.typedefs"

return {
  name = "remote-server-auth",
  fields = {
    { consumer=typedefs.no_consumer },
    { config = {
        type = "record",
        fields = {
          { get_access_url = typedefs.url({ required = true }) },
          { get_appToken_url = typedefs.url({ required = true }) },
    }, }, },
  },
}
