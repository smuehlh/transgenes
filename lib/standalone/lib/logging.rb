require 'logger'

module Logging

    extend self

    def default_setup_commandline_tool
        file_logger = build_logger("optimiser.log", Logger::INFO)
        stderr_logger = build_logger(STDERR, Logger::WARN)
        [file_logger, stderr_logger]
    end

    def build_logger(output, level, is_simplify=false)
        logger = initialize_logger(output, level)
        customize_output_format(logger, is_simplify)
        setup_graceful_exit(logger)

        logger
    end

    private

    def initialize_logger(output, level)
        progname = "SequenceOptimizer"
        timeformat = "%Y-%m-%d %H:%M:%S"
        this_logger =
            if output.instance_of?(IO) || output.instance_of?(StringIO)
                Logger.new(output)
            else
                file = File.open(output, File::WRONLY | File::TRUNC | File::CREAT)
                file.puts "Created logfile on #{Time.now.strftime(timeformat)} by #{progname}."
                Logger.new(file)
            end
        this_logger.level = level
        this_logger.progname = progname
        this_logger.datetime_format = timeformat

        this_logger
    end

    def customize_output_format(this_logger, is_simplify)
        this_logger.formatter = proc do |severity, datetime, progname, msg|
            if is_simplify
                simplify(severity, datetime, progname, msg)
            else
                prettify_multiline_messages(severity, datetime, progname, msg)
            end
        end
    end

    def prettify_multiline_messages(severity, datetime, progname, msg)
        msg = msg.to_s
        patched_msg =
            if msg.include?("\n")
                spacer = "\n\t"
                "#{spacer}#{msg.gsub("\n",spacer)}"
            else
                msg
            end
        "#{severity} -- #{progname}: #{patched_msg}\n"
    end

    def simplify(severity, datetime, progname, msg)
        "#{severity} -- #{msg}\n"
    end

    def setup_graceful_exit(this_logger)
        at_exit {this_logger.close}
    end
end