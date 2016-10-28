Ougai
=====

[![Build Status](https://travis-ci.org/tilfin/ougai.svg?branch=master)](https://travis-ci.org/tilfin/ougai)
[![Gem Version](https://badge.fury.io/rb/ougai.svg)](https://badge.fury.io/rb/ougai)

A JSON logger is compatible with [bunyan](https://github.com/trentm/node-bunyan) for Node.js

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ougai'
```

And then execute:

```
$ bundle
```

Or install it yourself as:

```
$ gem install ougai
```

## Usage

**Ougai::Logger** is sub-class of original [Logger](https://docs.ruby-lang.org/ja/latest/class/Logger.html) in Ruby.

```ruby
require 'rubygems'
require 'ougai'

logger = Ougai::Logger.new(STDOUT)
```

### log only a message

```ruby
logger.info('Information!')
```

```json
{"name":"main","hostname":"mint","pid":14607,"level":30,"time":"2016-10-16T22:26:48.835+09:00","v":0,"msg":"Information!"}
```

### log only a data

```ruby
logger.info({
  msg: 'Request', method: 'GET', path: '/login',
  format: 'html', controller: 'LoginController',
  action: 'new', status: 200
})
logger.debug(user: { name: 'Taro', age: 19 })
```

```json
{"name":"main","hostname":"mint","pid":9044,"level":30,"time":"2016-10-28T17:58:53.668+09:00","v":0,"msg":"Request","method":"GET","path":"/login","format":"html","controller":"LoginController","action":"new","status":200}
{"name":"main","hostname":"mint","pid":9044,"level":20,"time":"2016-10-28T17:58:53.668+09:00","v":0,"msg":"No message","user":{"name":"Taro","age":19}}
```

If a data does not contain `msg` field, msg is set `default_message` attribute value of a Logger. its default is 'No message'.

```ruby
logger.default_message = 'User dump'
logger.debug(user: { name: 'Taro', age: 19 })
```

```json
{"name":"main","hostname":"mint","pid":9303,"level":20,"time":"2016-10-28T18:03:50.118+09:00","v":0,"msg":"User dump","user":{"name":"Taro","age":19}}
```

### log only an exception

```ruby
begin
  raise StandardError, 'some error'
rescue => ex
  logger.error(ex)
end
```

```json
{"name":"main","hostname":"mint","pid":4422,"level":50,"time":"2016-10-22T13:05:02.989+09:00","v":0,"msg":"some error","err":{"name":"StandardError","message":"some error","stack":"main.rb:24:in `<main>'"}}
```

### log with a message and custom data

```ruby
logger.debug('Debugging', data_id: 1, data_flag: true)
logger.debug('Debug!', custom_data: { id: 1, name: 'something' })
```

```json
{"name":"main","hostname":"mint","pid":14607,"level":20,"time":"2016-10-16T22:26:48.836+09:00","v":0,"msg":"Debugging","custom_data":{"id":1,"name":"something"}}
{"name":"main","hostname":"mint","pid":14607,"level":20,"time":"2016-10-16T22:26:48.836+09:00","v":0,"msg":"Debug!","data_id":1,"data_flag":true}
```

### log with a message and an exception

```ruby
begin
  raise StandardError, 'fatal error'
rescue => ex
  logger.fatal('Unexpected!', ex)
end
```

```json
{"name":"main","hostname":"mint","pid":14607,"level":60,"time":"2016-10-16T22:26:48.836+09:00","v":0,"msg":"Unexpected!","err":{"name":"StandardError","message":"fatal error","stack":"main.rb:12:in `<main>'"}}
```

### log with a message, an exception and custom data

```ruby
begin
  1 / 0
rescue => ex
  logger.error('Caught error', ex, reason: 'zero spec')
end
```

```json
{"name":"main","hostname":"mint","pid":14607,"level":50,"time":"2016-10-16T22:26:48.836+09:00","v":0,"msg":"Caught error","err":{"name":"ZeroDivisionError","message":"divided by 0","stack":"main.rb:18:in `/'\n ...'"},"reason":"zero spec"}
```


## View log by node-bunyan

Install [bunyan](https://github.com/trentm/node-bunyan) via NPM

```
$ npm install -g bunyan
```

Pass a log file to command `bunyan`

```
$ bunyan output.log
[2016-10-16T22:26:48.835+09:00]  INFO: main/14607 on mint: Info message!
[2016-10-16T22:26:48.836+09:00] DEBUG: main/14607 on mint: Debugging (data_id=1, data_flag=true)
[2016-10-16T22:26:48.836+09:00] DEBUG: main/14607 on mint: Debug!
    custom_data: {
      "id": 1,
      "name": "something"
    }
[2016-10-16T22:26:48.836+09:00] FATAL: main/14607 on mint: Unexpected!
    main.rb:12:in `<main>'
[2016-10-16T22:26:48.836+09:00] ERROR: main/14607 on mint: Caught error (reason="z
    main.rb:18:in `/'
      main.rb:18:in `<main>'
```


## License

[MIT](LICENSE.txt)
