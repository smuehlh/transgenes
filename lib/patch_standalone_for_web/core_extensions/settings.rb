module CoreExtensions
    module Settings

        extend self

        def setup(kind)
            setup_errorhandling # ALWAYS setup error handling
            case kind
            when "logger" then setup_logger
            end
        end

        def close_logger
            $logger.close
        end

        private

        def setup_errorhandling
            ErrorHandling.is_commandline_tool = false
        end

        def setup_logger
            $logger = Logging.setup(
                File.join(Rails.root, "log", "webinput_to_gene.log"),
                Logger::WARN
            )
        end
    end
end