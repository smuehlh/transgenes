module CoreExtensions
    module Settings

        extend self

        def setup
            setup_errorhandling
            setup_logger
        end

        def setup_for_debugging
            setup
            $logger.level = Logger::DEBUG
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
            $logger.close if $logger

            @file = StringIO.new
            $logger = Logging.build_logger(@file, Logger::INFO, simplify_log=true)
        end
    end
end