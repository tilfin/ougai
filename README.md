Ougai
=====

[![Gem Version](https://badge.fury.io/rb/ougai.svg)](https://badge.fury.io/rb/ougai)
[![Build Status](https://travis-ci.org/tilfin/ougai.svg?branch=master)](https://travis-ci.org/tilfin/ougai)
[![Code Climate](https://codeclimate.com/github/tilfin/ougai/badges/gpa.svg)](https://codeclimate.com/github/tilfin/ougai)
[![Test Coverage](https://codeclimate.com/github/tilfin/ougai/badges/coverage.svg)](https://codeclimate.com/github/tilfin/ougai/coverage)

A JSON logging system is capable of handling a message, data or an exception easily.
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


## Use on Rails

### Define a custom logger

Add following code to `lib/your_app/logger.rb`
A custom logger includes LoggerSilence because Rails logger must support `silence` feature.

```ruby
module YourApp
  class Logger < Ougai::Logger
    include ActiveSupport::LoggerThreadSafeLevel
    include LoggerSilence

    def initialize(*args)
      super
      after_initialize if respond_to? :after_initialize
    end

    def create_formatter
      if Rails.env.development? || Rails.env.test?
        Ougai::Formatters::Readable.new
      else
        Ougai::Formatters::Bunyan.new
      end
    end
  end
end
```

### for Development

Add following code to `config/environments/development.rb`

```ruby
Rails.application.configure do
  ...

  config.logger = YourApp::Logger.new(STDOUT)
end
```

### for Production

Add following code to the end block of `config/environments/production.rb`

```ruby
Rails.application.configure do
  ...

  if ENV["RAILS_LOG_TO_STDOUT"].present?
    config.logger = YourApp::Logger.new(STDOUT)
  else
    config.logger = YourApp::Logger.new(config.paths['log'].first)
  end
end
```

### With Lograge

You must modify [lograge](https://github.com/roidrage/lograge) formatter like *Raw*.
The following code set request data to `request` field of JSON.

```ruby
Rails.application.configure do
  config.lograge.enabled = true
  config.lograge.formatter = Class.new do |fmt|
    def fmt.call(data)
      { msg: 'Request', request: data }
    end
  end
end
```

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

## License

[MIT](LICENSE.txt)
