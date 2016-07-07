class Logger

    def initialize
        @fh = File.new("optimizer.log", "w")
    end

    def write(str)
        @fh.puts str
    end

    def close
        @fh.close
    end
end