require "http/client"
require "json"

module Crambda
  VERSION = "0.0.1"

  struct Context
    getter function_name : String
    getter function_version : String
    getter memory_limit_in_mb : UInt32
    getter log_group_name : String
    getter log_stream_name : String
    getter aws_request_id : String
    getter invoked_function_arn : String
    getter deadline_ms : Int64
    getter identity : JSON::Any
    getter client_context : JSON::Any

    def initialize(@function_name, @function_version, @memory_limit_in_mb,
                   @log_group_name, @log_stream_name, @aws_request_id, @invoked_function_arn,
                   @deadline_ms, @identity, @client_context)
    end

    def get_remaining_time_in_millis
      @deadline_ms - Time.now.to_unix_ms
    end
  end

  def self.run_handler(handler : Proc(JSON::Any, Context, Object))
    function_name = ENV["AWS_LAMBDA_RUNTIME_API"]
    function_version = ENV["AWS_LAMBDA_FUNCTION_VERSION"]
    memory_limit_in_mb = UInt32.new(ENV["AWS_LAMBDA_FUNCTION_MEMORY_SIZE"])
    log_group_name = ENV["AWS_LAMBDA_LOG_GROUP_NAME"]
    log_stream_name = ENV["AWS_LAMBDA_LOG_STREAM_NAME"]
    host, port = ENV["AWS_LAMBDA_RUNTIME_API"].split(':')

    client = HTTP::Client.new(host, port)

    while true
      res = client.get("/2018-06-01/runtime/invocation/next")
      if res.status_code != 200
        raise "Unexpected response when invoking: #{res.status_code}"
      end

      ENV["_X_AMZN_TRACE_ID"] = res.headers["Lambda-Runtime-Trace-Id"]? || ""

      context = Context.new(
        function_name,
        function_version,
        memory_limit_in_mb,
        log_group_name,
        log_stream_name,
        res.headers["Lambda-Runtime-Aws-Request-Id"],
        res.headers["Lambda-Runtime-Invoked-Function-Arn"],
        Int64.new(res.headers["Lambda-Runtime-Deadline-Ms"]),
        JSON.parse(res.headers["Lambda-Runtime-Cognito-Identity"]? || "null"),
        JSON.parse(res.headers["Lambda-Runtime-Client-Context"]? || "null"),
      )

      result = handler.call(JSON.parse(res.body), context)

      res = client.post("/2018-06-01/runtime/invocation/#{context.aws_request_id}/response", body: result.to_json)
      if res.status_code != 202
        raise "Unexpected response when responding: #{res.status_code}"
      end
    end
  end
end
