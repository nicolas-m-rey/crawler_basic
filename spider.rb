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

    def enqueue(url, method, data = {})
        return if @handlers[url]
        @urls << url
        @handlers[url] ||= { method: method, data: data }
      end

    def record(data = {})
        @results << data
    end

    def results
        return enum_for(:results) unless block_given?

        index = @results.length
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


class ApiList
    attr_reader :root, :handler
    
    def initialize (root: "https://apilist.fun", handler: :process_index, **options)
        @root = root
        @handler = handler
        @options = options
    end

    def results(&block)
        spider.results(&block)
    end

    def process_index(page, data = {})
        puts "processing index..."
        page.links_with(href: %r{\?page=\d+}).each do |link|
            spider.enqueue(link.href, :process_index)
        end

        page.links_with(href: %r{/api/\w+$}).each do |link|
            spider.enqueue(link.href, :process_api, name: link.text)
        end
    end

    def process_api(page, data = {})
        print "processing api "
        fields = page.search("#tabs-content .field").each_with_object({}) do |tage, o|
            key = tag.search("label").text.strip.downcase.gsub(%r{[^\w]+}, ' ').gsub(%r{\s+}, "_").to_sym
            val = tag.search("span").text
            o[key] = val
        end

        # categories = page.search("article.node-api .tags").first.text.strip.split(/\s+/)

        spider.record data.merge(fields)#.merge(categories: categories)
    end

    

    private

    def spider
        @spider ||= Spider.new(self, @options)
    end


end

spider = ApiList.new

    spider.results.lazy.take(10).each_with_index do |result, i|
        puts "%-3s: %s" % [i, result.inspect]
    end

puts "web crawl complete"