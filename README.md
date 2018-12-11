# crambda

[Crystal](https://crystal-lang.org/) AWS Lambda custom runtime

## Installation

1. Add the dependency to your `shard.yml`:
```yaml
dependencies:
  crambda:
    github: lambci/crambda

targets:
  bootstrap:
    main: src/main.cr
```
2. Run `shards install`

## Usage

(Assuming this is your `src/main.cr` or similar from above)

```crystal
require "json"
require "crambda"

def handler(event : JSON::Any, context : Crambda::Context)
  pp context
  JSON.parse("[1, 2]")
end

Crambda.run_handler(->handler(JSON::Any, Crambda::Context))
```

Where `Crambda.run_handler` expects a handler that takes a `JSON::Any` event
and a `Context`, and returns a `JSON::Any` response:

```crystal
def self.run_handler(handler : Proc(JSON::Any, Context, JSON::Any))
  # ...
end
```

And `Context` is a class that looks like this:

```crystal
class Context
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

  def get_remaining_time_in_millis
    # ...
  end
nd
```

## Compiling and uploading to AWS Lambda

### Static binary (easy, but larger and slower)

Creating a static binary is the easiest method, but will be larger and slower than using dynamic libraries.

If you're on Linux already, you can do:

```console
shards install

shards build --release --no-debug --static

strip bin/bootstrap # optional, to reduce size
```

Then package up `bootstrap` at the top level of a zipfile:

```console
cd bin
zip lambda.zip bootstrap
```

And upload `lambda.zip` to your custom runtime AWS Lambda.

If you're not on Linux, you can run the install step locally (if you have crystal – `brew install crystal` on MacOS),
and then compile in a docker container:

```console
shards install

docker run --rm -v "$PWD":/app -w /app crystallang/crystal sh -c \
  'shards build --release --no-debug --static && strip bin/bootstrap'
```

(then zip up your `bootstrap` executable as above)

### Dynamically linked binary (more steps, but smaller and faster)

The only libs that need to be statically linked in your binary (ie, that don't
exist on AWS Lambda) are `libevent`, `libgc` and `libcrystal`. By default, crystal
statically links the last two anyway, but `libevent` doesn't exist on Lambda, so
either needs to be uploaded as a separate `.so` alongside your `bootstrap`, or
compiled in.

The most straightforward way to link these libs into your binary is to use the
ones supplied in the `ext` directory in `crambda`, as follows:

First build a cross-compiled version of your Lambda function (you can do this
on any machine that has `crystal`, including MacOS):

```console
shards install

PKG_CONFIG_PATH=lib/crambda/ext crystal build src/main.cr -o bin/bootstrap \
  --release --no-debug --cross-compile --target x86_64-unknown-linux-gnu

# Ignore the command it outputs – it needs to be modified slightly as below
```

This will create a `bin/bootstrap.o` object file that you can link in a
Lambda-like environment – eg, a machine running Amazon Linux, or in a Docker container:

```console
docker run --rm -v "$PWD":/var/task lambci/lambda:build-provided cc bin/bootstrap.o -o bin/bootstrap -s \
  -rdynamic -lz -lssl -lcrypto -lpcre -lm -lgc -lpthread -lcrystal -levent -lrt -ldl -Llib/crambda/ext
```

This will place the `bootstrap` binary in `bin` where you can zip it up and
upload to Lambda as shown above in the static binary instructions.

If you're using a different version of `crystal` from the one supplied in `ext` (currently `0.27.0`),
then you'll need to replace `-lcrystal` with the path to the version of
libcrystal that matches your environment.
