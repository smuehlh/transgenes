require 'optparse'

class CommandlineOptions
    attr_reader :input, :output, :strategy,
        # optional params
        :select_by,
        :utr5prime, :utr3prime,
        :input_line, :utr5prime_line, :utr3prime_line,
        :remove_first_intron,
        :ese,
        :ese_strategy,
        :stay_in_subbox_for_6folds,
        :verbose

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

    def default_for_select_by_depending_on_strategy
        @strategy == "max-gc" ? "high" : "mean"
    end

    def default_for_ese_strategy
        "deplete"
    end

    def mandatory_arguments
        %w(@input @output @strategy)
    end

    def optional_arguments
        %w(
            @select_by
            @input_line
            @utr5prime @utr5prime_line @utr3prime @utr3prime_line
            @remove_first_intron
            @ese
            @ese_strategy
            @stay_in_subbox_for_6folds
            @verbose
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
        $logger.info("Program call") {@program_call}
    end

    def parse_options
        opt_parser = argument_specification
        opt_parser.parse(@args)

        set_defaults_for_unset_optional_arguments_that_cant_remain_unset
        ensure_mandatory_arguments_are_set
        ensure_dependencies_are_met

        rescue OptionParser::MissingArgument,
            OptionParser::InvalidArgument,
            OptionParser::InvalidOption,
            OptionParser::AmbiguousOption => exception

            exception_str = exception.to_s
            exception_str[0] = exception_str[0].capitalize
            ErrorHandling.abort_with_error_message(
                "argument_error", "CommandlineOptions", exception_str
            )
    end

    def set_defaults_for_unset_optional_arguments_that_cant_remain_unset
        unless @select_by
            @select_by = default_for_select_by_depending_on_strategy
            $logger.warn("Option select-by was not set. Defaults to '#{@select_by}'")
        end

        if @ese && @ese_strategy.nil?
            @ese_strategy = default_for_ese_strategy
            $logger.warn("Option ese-strategy was not set. Defaults to '#{@ese_strategy}'")
        end
    end

    def argument_specification
        OptionParser.new do |opts|
            opts.banner = "Enhance mammalian transgenes."
            opts.separator "Contact: Laurence Hurst (l.d.hurst@bath.ac.uk)"
            opts.separator ""
            opts.separator "Usage: ruby #{File.basename($PROGRAM_NAME)} -i input -o output -s strategy [options]"

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
            opts.on("-s", "--strategy STRATEGY", ["raw", "humanize", "gc", "max-gc"],
                "Strategy for altering the sequence.",
                "Select one of: 'raw', 'humanize', 'gc' or 'max-gc'.",
                "raw - Leave the sequence as is.", "May be specified only in combination with an ESE list (--ese).",
                "humanize - Match human codon usage.", "May be specified with/ without an ESE list.",
                "gc - Match position-dependent GC content of 1- or 2-exon genes.", "May be specified with/ without an ESE list.",
                "max-gc - Maximize GC3 content.", "May be specified with/ without an ESE list.", "Strategy to select the best variant must be set to 'high'.") do |opt|
                @strategy = opt
            end

            # optional arguments
            opts.separator ""
            opts.separator "Optional arguments:"
            opts.on("-l", "--line LINE NUMBER", Integer,
                "Starting line of gene description to read.") do |line|
                @input_line = line
            end
            opts.on("--utr-5 FILE",
                "Path to 5' UTR file, in FASTA format.") do |path|
                FileHelper.file_exist_or_die(path)
                @utr5prime = path
            end
            opts.on("--utr-3 FILE",
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
                "Remove all introns from CDS including the first.", "If not specified, the first intron is kept.") do |opt|
                @remove_first_intron = true
            end
            opts.on("-e", "--ese FILE",
                "Path to ESE file, one motif per line.",
                "All motifs must be of same length and in #{Constants.min_motif_length}-#{Constants.max_motif_length} bp range.",
                "To tweak the sequence by ESE resemblance only, set --strategy to 'raw'.") do |path|
                FileHelper.file_exist_or_die(path)
                @ese = path
            end
            opts.on("--ese-strategy STRATEGY", ["deplete", "enrich"],
                "Strategy for scoring codons by their ESE resemblance.",
                "(Selection will also be applied to select the best variant)",
                "Select one of: 'deplete' or 'enrich'.",
                "deplete - Deplete ESEs in vicinity to deleted introns.",
                "enrich - Enrich ESEs in vicinity to deleted introns.",
                "If not specified, defaults to 'deplete'.") do |opt|
                @ese_strategy = opt
            end
            opts.on("-c", "--stay-in-codon-box",
                "6-fold degenerates: Stay in the respective (2- or 4-fold) codon box", "when selecting a synonymous codon.", "If not specified, all 6 codons are considered.") do |opt|
                @stay_in_subbox_for_6folds = true
            end
            opts.on("-b", "--select-by STRATEGY", ["mean", "high", "low"],
                "Strategy for selecting which of the generated variants is best.",
                "Take ESE coverage into account when multiple variants have same GC3.",
                "Select one of: 'mean', 'high' or 'low'.",
                "mean - Closest GC3 to the average human GC3 content.",
                "high - Highest GC3 of all variants.",
                "low - Lowest GC3 of all variants.",
                "If not specified, defaults to 'mean' ('high' if strategy is set to 'max-gc').") do |opt|
                @select_by = opt
            end

            opts.separator ""
            opts.on("-v", "--verbose", "Produce verbose log.") do |opt|
                @verbose = true
            end
            opts.on_tail("-h", "--help", "Show this message") do
                puts opts
                exit
            end
        end
    end

    def ensure_mandatory_arguments_are_set
        mandatory_arguments.each do |arg|
            ErrorHandling.abort_with_error_message(
                "missing_mandatory_argument", "CommandlineOptions", instance_variable_to_argument(arg)
            ) unless is_argument_set(arg)
        end
    end

    def ensure_dependencies_are_met
        ErrorHandling.abort_with_error_message(
            "invalid_argument_combination", "CommandlineOptions",
            "Nothing to do for the combination: 'raw'-strategy/ no ESEs"
        ) if strategy_raw_specified_without_ese_list
        ErrorHandling.warn_with_error_message(
            "unused_ese_strategy", "CommandlineOptions"
        ) if ese_strategy_specified_without_ese_list
        ErrorHandling.abort_with_error_message(
            "invalid_argument_combination", "CommandlineOptions",
            "'max-gc'-strategy/ '#{@select_by}'-select best variant.\nSet strategy to select best variant to 'high'"
        ) if strategy_max_gc_specified_without_select_by_set_to_high
        ErrorHandling.warn_with_error_message(
            "unused_utr_line", "CommandlineOptions", "5'UTR"
        ) if utr_line_specified_without_file(@utr5prime, @utr5prime_line)
        ErrorHandling.warn_with_error_message(
            "unused_utr_line", "CommandlineOptions", "3'UTR"
        ) if utr_line_specified_without_file(@utr3prime, @utr3prime_line)
    end

    def utr_line_specified_without_file(file, line)
        file.nil? && line
    end

    def strategy_raw_specified_without_ese_list
        @strategy == "raw" && @ese.nil?
    end

    def ese_strategy_specified_without_ese_list
        @ese_strategy && @ese.nil?
    end

    def strategy_max_gc_specified_without_select_by_set_to_high
        @strategy == "max-gc" && @select_by != "high"
    end
end