require "mechanize"

class Spider
    REQUEST_INTERVAL = 5
    MAX_URLS = 1000
    
    def initialize(processor, attrs = {})
        @processor = processor

        @urls      = []
        @results   = []
        @handlers  = {}

        @interval = attrs.fetch(:interval, REQUEST_INTERVAL)
        @max_urls = attrs.fetch(:max_urls, MAX_URLS)

        enqueue(processor.root, processor.handler)
    end


    def enqueue(url, method)
        url = agent.resolve(url).to_s
        return if @handlers[url]
        @urls << url
        @handlers[url] ||= {method: method, data: {} }
    end

    def record(data = {})
        @results << data
    end

    private

    def agent
        @agent ||= Mechanize.new
    end
end