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

Crambda.start_lambda do |event, context|
  puts context.pretty_inspect
  JSON.parse("[1, 2]")
end
```

## Compiling and uploading to AWS Lambda

Either create a static binary (this will be larger and slower):

```
docker run -v "$PWD":/app -w /app crystallang/crystal sh -c 'shards build --release --static && strip bin/bootstrap'
cd bin
zip lambda.zip bootstrap
```

OR create your own Docker image to work from:

```
FROM lambci/lambda:build-provided

RUN yum install -y libevent-devel pcre-devel

RUN curl -sSL https://github.com/crystal-lang/crystal/releases/download/0.27.0/crystal-0.27.0-1-linux-x86_64.tar.gz | \
  tar -xz -C /usr/local --strip-components 1
```

And then create your own zip with libevent (as this is not already included on Lambda)

```
docker run -v "$PWD":/var/task <your-docker-image> sh -c 'shards build --release && strip bin/bootstrap'
cp lib/crambda/libevent-2.0.so.5 bin/
cd bin
zip lambda.zip bootstrap libevent-2.0.so.5
```
