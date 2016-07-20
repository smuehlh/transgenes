module CoreExtensions
    module Settings

        extend self

        def setup_logger
            $logger = Logging.setup(
                File.join(Rails.root, "log", "webinput_to_gene.log"),
                Logger::WARN
            )
        end

        def close_logger
            $logger.close
        end
    end
end