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
            close_logger # important: first read, than close the logger.

            content
        end

        private

        def setup_errorhandling
            ErrorHandling.is_commandline_tool = false
        end

        def setup_logger
            @file = StringIO.new
            $logger = Logging.build_logger(@file, Logger::WARN, simplify_log=true)
        end

        def close_logger
            $logger.close
        end
    end
end