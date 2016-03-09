require 'optparse'

class CommandlineOptions
    attr_reader :input, :output

    @@mandatory_arguments = ["@input", "@output"]

    def initialize(args)
        @args = args

        # init options
        @input = nil
        @output = nil

        # call parser for every class instance
        ensure_help_is_printed_if_no_options_given
        parse_options
    end

    def parse_options
        opt_parser = OptionParser.new do |opts|
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

            # optional arguments
            opts.separator ""
            opts.separator "Optional arguments:"

            opts.separator ""
            opts.on_tail("-h", "--help", "Show this message") do 
                # delete all hidden params from help
                puts opts
                exit
            end            
        end

        opt_parser.parse(@args)

        ensure_mandatory_arguments_are_set

        # TODO ensure dependencies are met...

        # use the own format of fatal error messages!               
        rescue OptionParser::MissingArgument, OptionParser::InvalidArgument, OptionParser::InvalidOption, OptionParser::AmbiguousOption => exception
            abort exception.to_s.capitalize
    end

    def ensure_help_is_printed_if_no_options_given
        @args.push "-h" if @args.empty?
    end

    def ensure_mandatory_arguments_are_set
        @@mandatory_arguments.each do |arg|
            opt_str = arg.sub("@", "--")
            abort "Missing mandatory option: '#{opt_str}'." if 
                ! instance_variable_get(arg) 
        end
    end
end