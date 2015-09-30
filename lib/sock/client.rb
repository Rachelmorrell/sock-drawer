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

    private

    def channel_name(postfix)
      "#{@name}/#{postfix}"
    end
  end
end
