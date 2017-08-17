Ougai
=====

[![Gem Version](https://badge.fury.io/rb/ougai.svg)](https://badge.fury.io/rb/ougai)
[![Build Status](https://travis-ci.org/tilfin/ougai.svg?branch=master)](https://travis-ci.org/tilfin/ougai)
[![Code Climate](https://codeclimate.com/github/tilfin/ougai/badges/gpa.svg)](https://codeclimate.com/github/tilfin/ougai)
[![Test Coverage](https://codeclimate.com/github/tilfin/ougai/badges/coverage.svg)](https://codeclimate.com/github/tilfin/ougai/coverage)

A structured JSON logging system is capable of handling a message, structured data or an exception easily.
It is compatible with [Bunyan](https://github.com/trentm/node-bunyan) for Node.js.
It can also output human readable format for the console.

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

### log with an exception and custom data

```ruby
begin
  raise StandardError, 'some error'
rescue => ex
  logger.error(ex, error_id: 999)
end
```

```json
{"name":"main","hostname":"mint","pid":13962,"level":50,"time":"2016-10-28T23:44:52.144+09:00","v":0,"error_id":999,"err":{"name":"StandardError","message":"some error","stack":"main.rb:40:in `<main>'"}}
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

### logs with blocks

```ruby
logger.info { 'Hello!' }

logger.debug do
  ['User dump', { name: 'Taro', age: 15 }]
end

logger.error do
  ['Failed to fetch info', ex, { id: 10 }]
end

loggger.fatal { ex }

loggger.fatal do
  ['Unexpected', ex]
end
```

To specify more than one of a message, an exception and custom data, the block returns them as an array.

### Adding custom fields to all logs

The fields of `with_fields` add to all logs as is.

```ruby
logger.with_fields = { version: '1.1.0' }
logger.debug(user: { name: 'Taro', age: 19 })
logger.info('Hello!', user: { name: 'Jiro' }, version: '2.3')
```

```json
{"name":"test","hostname":"mint","pid":30182,"level":20,"time":"2017-07-22T20:52:12.332+09:00","v":0,"version":"1.1.0","msg":"No message","user":{"name":"Taro","age":19}}
{"name":"test","hostname":"mint","pid":30308,"level":30,"time":"2017-07-22T20:53:54.314+09:00","v":0,"version":"2.3","user":{"name":"Jiro"},"msg":"Hello!"}
```

If any field of with_fields is specified in each log, the field is overridden.
But if the field's type is *Array*, both with_field value and logging value are merged with `concat` and `uniq`.

### Create a child logger

`logger.child(with_fields)` creates a child logger of self. Its argument `with_fields` add to all logs the child logger outputs. A child logger can also create its child logger.

```ruby
logger = Ougai::Logger.new(STDOUT)
logger.with_fields = { app: 'yourapp', tags: ['service'], kind: 'main' }

child_logger = logger.child({ tags:['user'], kind: 'logic' })
logger.info('Created child logger')

child_logger.info('Created a user', name: 'Mike')

gc_logger = child_logger.child({ kind: 'detail' })
child_logger.info('Created grand child logger')

gc_logger.debug('something detail', age: 34, weight: 72)
```

```json
{"name":"main","hostname":"mint2","pid":8342,"level":30,"time":"2017-08-01T22:07:20.400+09:00","v":0,"app":"yourapp","tags":["service"],"kind":"main","msg":"Created child logger"}
{"name":"Mike","hostname":"mint2","pid":8342,"level":30,"time":"2017-08-01T22:07:20.400+09:00","v":0,"app":"yourapp","tags":["service","user"],"kind":"logic","msg":"Created a user"}
{"name":"main","hostname":"mint2","pid":8342,"level":30,"time":"2017-08-01T22:07:20.400+09:00","v":0,"app":"yourapp","tags":["service","user"],"kind":"logic","msg":"Created grand child logger"}
{"name":"main","hostname":"mint2","pid":8342,"level":20,"time":"2017-08-01T22:07:20.400+09:00","v":0,"app":"yourapp","tags":["service","user"],"kind":"detail","age":34,"weight":72,"msg":"something detail"}
```

If any field exists in both parent log and child log, the parent value is overridden or merged by child value.

### Hook before logging

Setting `before_log` of logger or child an *lambda* with `data` field, a process can be run before log each output.

* Adding variable data (like Thread ID) to logging data can be defined in common.
* Returning `false` in *lambda*, the log is cancelled and does not output.
* The *before_log* of child logger is run ahead of the parent logger's.

```ruby
logger.before_log = lambda do |data|
  data[:thread_id] = Thread.current.object_id.to_s(36)
end

logger.debug('on main thread')
Thread.new { logger.debug('on another thread') }
```

```json
{"name":"main","hostname":"mint","pid":13975,"level":20,"time":"2017-08-06T15:35:53.435+09:00","v":0,"msg":"on main thread","thread_id":"gqe0ava6c"}
{"name":"main","hostname":"mint","pid":13975,"level":20,"time":"2017-08-06T15:35:53.435+09:00","v":0,"msg":"on another thread","thread_id":"gqe0cb14g"}
```

### Using broadcast, log output plural targets

`Ougai::Logger.broadcast` can be used to like `ActiveSupport::Logger.broadcast`.

#### An example

Original `logger` outputs STDOUT and `error_logger` outputs `./error.log`.
Every calling for `logger` is propagated to `error_logger`.

```ruby
logger = Ougai::Logger.new(STDOUT)

error_logger = Ougai::Logger.new('./error.log')
logger.extend Ougai::Logger.broadcast(error_logger)

logger.level = Logger::INFO
logger.info('Hello!')

error_logger.level = Logger::ERROR
logger.error('Failed to do something.')

logger.level = Logger::WARN # error_logger level is also set WARN by propagation
logger.warn('Ignored something.')
```

##### STDOUT

```json
{"name":"main","hostname":"mint","pid":24915,"level":30,"time":"2017-08-16T17:23:42.415+09:00","v":0,"msg":"Hello!"}
{"name":"main","hostname":"mint","pid":24915,"level":50,"time":"2017-08-16T17:23:42.416+09:00","v":0,"msg":"Failed to do something."}
{"name":"main","hostname":"mint","pid":24915,"level":40,"time":"2017-08-16T17:23:42.416+09:00","v":0,"msg":"Ignored something."}
```

##### error.log

```json
{"name":"main","hostname":"mint","pid":24915,"level":50,"time":"2017-08-16T17:23:42.415+09:00","v":0,"msg":"Failed to do something."}
{"name":"main","hostname":"mint","pid":24915,"level":40,"time":"2017-08-16T17:23:42.416+09:00","v":0,"msg":"Ignored something."}
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


## Use human Readable formatter for console

Add awesome_print to Gemfile and `bundle`

```ruby
gem 'awesome_print'
```

Set *Ougai::Formatters::Readable* instance to `formatter` accessor

```ruby
require 'rubygems'
require 'ougai'

logger = Ougai::Logger.new(STDOUT)
logger.formatter = Ougai::Formatters::Readable.new
```

### Screen result example

![Screen Shot](https://github.com/tilfin/ougai/blob/images/ougai_readable_format.png?raw=true)


### Output example on development

If you modify `application_controller.rb` as

```ruby
class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  def hello
    logger.debug 'Call action', somefield: 'somevalue'
    render plain: 'Hello!'
  end
end
```

logger outputs

```
[2016-11-03T15:11:24.847+09:00] DEBUG: Call action
{
    :somefield => "somevalue"
}
[2016-11-03T15:11:24.872+09:00] INFO: Request
{
    :request => {
            :method => "GET",
              :path => "/",
            :format => :html,
        :controller => "ApplicationController",
            :action => "hello",
            :status => 200,
          :duration => 30.14,
              :view => 3.35,
                :db => 0.0
    }
}
```

## How to use with famous products and libraries

- [Use as Rails logger](https://github.com/tilfin/ougai/wiki/Use-as-Rails-logger)
- [Customize Sidekiq logger](https://github.com/tilfin/ougai/wiki/Customize-Sidekiq-logger)
- [Forward logs to Fluentd](https://github.com/tilfin/ougai/wiki/Forward-logs-to-Fluentd)

## License

[MIT](LICENSE.txt)
