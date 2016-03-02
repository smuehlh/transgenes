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
        parse_options
    end

    def parse_options
        opt_parser = OptionParser.new do |opts|
            opts.banner = "SequenceOptimiser enhances transgenes by removing ESEs"
            opts.separator "Contact: Laurence Hurst (l.d.hurst@bath.ac.uk)"
            opts.separator ""
            opts.separator "Usage: ruby sequence_optimiser.rb -i input -o output [options]"

            opts.on("-i", "--input GFF",
                "Path to input file, in GFF format.") do |path|
                FileHelper.file_exist_or_die(path)
                @input = path
            end
            opts.on("-o", "--output GFF",
                "Path to output file, in GFF format.") do |path|
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

        # ensure dependencies are met...

        # use the own format of fatal error messages!               
        rescue OptionParser::MissingArgument, OptionParser::InvalidArgument, OptionParser::InvalidOption, OptionParser::AmbiguousOption => exc
            abort exc.to_s.capitalize
    end

    def ensure_mandatory_arguments_are_set
        @@mandatory_arguments.each do |arg|
            opt_str = arg.gsub("@", "--")
            abort "Missing mandatory option: '#{opt_str}'." if 
                ! instance_variable_get(arg) 
        end
    end
end