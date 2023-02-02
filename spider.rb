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

    def results
        return enum_for(:results) unless block_given?

        index - @results.length
        enqueued_urls.each do |url, handler|

            # process url
            @processor.send(handler[:method], agent.get(url), handler[:data])

            if block_given? && @results.length > index
                yield @results.last
                index += 1
            end

            # crawl delay
            sleep @interval if @interval > 0
        end
    end

    private

    def agent
        @agent ||= Mechanize.new
    end

    def enqueued_urls
        Enumerator.new do |y|
            index = 0
            while index < @urls.count && index <= @max_urls
                url = @urls[index]
                index += 1
                next unless url
                y.yield url, @handlers [url]
            end
        end
    end
end