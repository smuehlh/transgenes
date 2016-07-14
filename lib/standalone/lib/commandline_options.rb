require 'optparse'

class CommandlineOptions
    attr_reader :input, :output, :strategy,
        # optional params
        :utr5prime, :utr3prime,
        :input_line, :utr5prime_line, :utr3prime_line,
        :remove_first_intron,
        :ese

    def initialize(args)
        init_commandline_arguments(args)
        init_mandatory_arguments
        init_optional_arguments

        log_options
        parse_options
    end

    def init_commandline_arguments(args)
        @args = args
        @program_call = "#{$PROGRAM_NAME} #{args.join(" ")}"

        # if no arugments given: ensure help is printed
        @args.push "-h" if @args.empty?
    end

    def init_mandatory_arguments
        mandatory_arguments.each do |arg|
            instance_variable_set(arg, nil)
        end
    end

    def init_optional_arguments
        optional_arguments.each do |arg|
            instance_variable_set(arg, nil)
        end
    end

    def mandatory_arguments
        %w(@input @output @strategy)
    end

    def optional_arguments
        %w(
            @input_line
            @utr5prime @utr5prime_line @utr3prime @utr3prime_line
            @remove_first_intron
            @ese
        )
    end

    def is_argument_set(arg)
        instance_variable_get(arg)
    end

    def instance_variable_to_argument(str)
        # for mandatory arguments only
        case str
        when "@input" then "--input"
        when "@output" then "--output"
        when "@strategy" then "--strategy"
        else "Unknown argument. Use --help to view all available options."
        end
    end

    def log_options
        $logger.info("Programm call: #{@program_call}")
    end

    def parse_options
        opt_parser = argument_specification
        opt_parser.parse(@args)

        ensure_mandatory_arguments_are_set
        ensure_dependencies_are_met

        rescue OptionParser::MissingArgument,
            OptionParser::InvalidArgument,
            OptionParser::InvalidOption,
            OptionParser::AmbiguousOption => exception

            exception_str = exception.to_s
            exception_str[0] = exception_str[0].capitalize
            ErrorHandling.abort_with_error_message("argument_error", exception_str
            )
    end

    def argument_specification
        OptionParser.new do |opts|
            opts.banner = "Alter synonymous sites to enhance transgenes."
            opts.separator "Contact: Laurence Hurst (l.d.hurst@bath.ac.uk)"
            opts.separator ""
            opts.separator "Usage: ruby sequence_optimiser.rb -i input -o output [options]"

            opts.on("-i", "--input FILE",
                "Path to input file in one of the following formats:",
                "GeneBank record OR",
                "FASTA with exons in upper case and introns in lower case.") do |path|
                FileHelper.file_exist_or_die(path)
                @input = path
            end
            opts.on("-o", "--output FILE",
                "Path to output file, in FASTA format.") do |path|
                @output = path
            end
            opts.on("-s", "--strategy STRATEGY", ["raw", "humanize", "gc"],
                "Strategy for altering the sequence.",
                "Select one of: 'raw', 'humanized' or 'gc'.",
                "raw - Leave the sequence as is.", "May be specified only in combination with an ESE list (--ese).",
                "humanize - Match human codon usage.", "May be specified with/ without an ESE list.",
                "gc - Match GC content of 1- or 2-exon genes.", "May be specified with/ without an ESE list.") do |opt|
                @strategy = opt
            end

            # optional arguments
            opts.separator ""
            opts.separator "Optional arguments:"
            opts.on("-l", "--line LINE NUMBER", Integer,
                "Starting line of gene description to read.") do |line|
                @input_line = line
            end
            opts.on("-u", "--utr-5 FILE",
                "Path to 5' UTR file, in FASTA format.") do |path|
                FileHelper.file_exist_or_die(path)
                @utr5prime = path
            end
            opts.on("-v", "--utr-3 FILE",
                "Path to 3' UTR file, in FASTA format.") do |path|
                FileHelper.file_exist_or_die(path)
                @utr3prime = path
            end
            opts.on("--utr-5-line LINE NUMBER", Integer,
                "Starting line of 5' UTR description to read.") do |line|
                @utr5prime_line = line
            end
            opts.on("--utr-3-line LINE NUMBER", Integer,
                "Starting line of 3' UTR description to read.") do |line|
                @utr3prime_line = line
            end
            opts.on("-r", "--remove-first-intron",
                "Remove all introns from CDS including the first. If not specified, the first intron is kept.") do |opt|
                @remove_first_intron = true
            end
            opts.on("-e", "--ese FILE",
                "Path to ESE file, one motif per line.",
                "ESEs near introns that will be removed will be destroyed.") do |path|
                FileHelper.file_exist_or_die(path)
                @ese = path
            end
            opts.separator ""
            opts.on_tail("-h", "--help", "Show this message") do
                $logger.error(opts)
                exit
            end
        end
    end

    def ensure_mandatory_arguments_are_set
        mandatory_arguments.each do |arg|
            ErrorHandling.abort_with_error_message(
                "missing_mandatory_argument",instance_variable_to_argument(arg)
            ) unless is_argument_set(arg)
        end
    end

    def ensure_dependencies_are_met
        ErrorHandling.abort_with_error_message(
            "invalid_argument_combination",
            "Nothing to do for the combination: 'raw'-strategy/ no ESEs"
        ) if strategy_raw_specified_without_ese_list
        ErrorHandling.warn_with_error_message(
            "unused_utr_line", "5'UTR"
        ) if utr_line_specified_without_file(@utr5prime, @utr5prime_line)
        ErrorHandling.warn_with_error_message(
            "unused_utr_line", "3'UTR"
        ) if utr_line_specified_without_file(@utr3prime, @utr3prime_line)
    end

    def utr_line_specified_without_file(file, line)
        file.nil? && line
    end

    def strategy_raw_specified_without_ese_list
        @strategy == "raw" && @ese.nil?
    end
end