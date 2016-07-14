require 'logger'

module Logging

    extend self

    def default_setup_commandline_tool
        file_logger = setup("optimiser.log", Logger::INFO)
        stderr_logger = setup(STDERR, Logger::WARN)
        [file_logger, stderr_logger]
    end

    def setup(output, level)
        logger = initialize_logger(output, level)
        customize_output_format_of_multiline_messages(logger)
        setup_graceful_exit(logger)

        logger
    end

    private

    def initialize_logger(output, level)
        this_logger = Logger.new(output)
        this_logger.level = level
        this_logger.progname = "SequenceOptimizer"
        this_logger.datetime_format = "%Y-%m-%d %H:%M:%S"

        this_logger
    end

    def customize_output_format_of_multiline_messages(this_logger)
        original_formatter = Logger::Formatter.new
        this_logger.formatter = proc do |severity, datetime, progname, msg|
            patched_msg =
                if msg.include?("\n")
                    spacer = "\n\t"
                    "#{spacer}#{msg.gsub("\n",spacer)}"
                else
                    msg
                end
            original_formatter.call(severity, datetime, progname, patched_msg)
        end
    end

    def setup_graceful_exit(this_logger)
        at_exit {this_logger.close}
    end
end