require 'logger'
require 'json'
require 'time'
require 'socket'

module Ougai
  class BunyanFormatter < Logger::Formatter
    def initialize(app_name = nil, hostname = nil)
      @app_name = app_name || File.basename($0, ".rb")
      @hostname = hostname || Socket.gethostname
    end

    def call(severity, time, progname, data)
      JSON.generate({
        name: progname || @app_name,
        hostname: @hostname,
        pid: $$,
        level: to_level(severity),
        time: time.iso8601(3),
        v: 0
      }.merge(data)) + "\n"
    end

    def to_level(severity)
      case severity
      when 'INFO'
        30
      when 'WARN'
        40
      when 'ERROR'
        50
      when 'FATAL'
        60
      else # DEBUG
        20
      end
    end
  end
end
