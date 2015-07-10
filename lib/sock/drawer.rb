require "sock/drawer/version"
require 'em-websocket'
require 'em-hiredis'
require 'redis'
require 'logger'
require "sock/client"

module Sock
  DEFAULT_NAME = 'sock-hook'
  HOST = '0.0.0.0'
  PORT = 8020

  class Drawer
    def initialize(name: DEFAULT_NAME, socket_params: { host: HOST, port: PORT }, logger: Logger.new(STDOUT))
      @name = name
      @socket_params = socket_params
      @channels = {}
      @logger = logger
    end

    def start!
      EM.run do
        subscribe(@name)
        EventMachine::WebSocket.start(@socket_params) do |ws|
          ws.onopen { |handshake|
            @logger.info "sock opened on #{handshake.path}"
            sid = channel(@name + handshake.path).subscribe { |msg| ws.send(msg) }
            ws.onclose { channel(@name + handshake.path).unsubscribe(sid) }
          }
        end
      end
    end

    private

    def subscribe(subscription)
      @logger.info "Subscribing to: #{subscription + "*"}"
      pubsub.psubscribe(subscription + "*") { |c, msg|
        @logger.info "pushing c: #{c} msg: #{msg}"
        channel(c).push(msg)
      }
    end

    def channel(channel_name)
      @logger.info "creating/finding channel #{channel_name}"
      @channels[channel_name] ||= EM::Channel.new
    end

    def pubsub
      @pubsub ||= EM::Hiredis.connect.pubsub
    end
  end
end
