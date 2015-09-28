module Sock
  # Client is the interface for publishing events to Drawer
  class Client
    def initialize(name: DEFAULT_NAME,
                   logger: Logger.new(STDOUT),
                   redis: Redis.new)
      @logger = logger
      @name = name
      @redis = redis
    end

    # send a message to all subscribed listeners.
    def pub(msg, postfix: '')
      @logger.info "sending #{msg} on channel: #{channel_name(postfix)}"
      @redis.publish(channel_name(postfix), msg)
    end

    # subscribe to all events fired on a given channel
    def sub(channel, class_name, method)
      @logger.info "subscribing to #{channel_name(channel)}"

      message = {
        file: caller_locations(1, 1)[0].path,
        channel: channel_name(channel),
        class_name: class_name,
        method: method
      }
      @redis.publish(@name + '-channels/', message.to_json)
      # @redis.publish()
      # server.channel(channel_name(channel)).subscribe { |msg| block.call(msg) }
    end

    private

    def channel_name(postfix)
      "#{@name}/#{postfix}"
    end
  end
end
