module CoreExtensions
    module Settings

        extend self

        def setup(kind)
            setup_errorhandling # ALWAYS setup error handling
            case kind
            when "logger" then setup_logger
            end
        end

        def get_log_content
            @file.rewind
            content = @file.read
            $logger.close

            content
        end

        private

        def setup_errorhandling
            ErrorHandling.is_commandline_tool = false
        end

        def setup_logger
            @file = StringIO.new
            $logger = Logging.build_logger(@file, Logger::INFO, simplify_log=true)
        end
    end
end