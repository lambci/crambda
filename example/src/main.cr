require "json"
require "crambda"

def handler(event : JSON::Any, context : Crambda::Context)
  pp context
  JSON.parse("[1, 2]")
end

Crambda.run_handler(->handler(JSON::Any, Crambda::Context))
