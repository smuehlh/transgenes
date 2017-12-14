class RestrictionEnzymeToGene

    attr_reader :motifs

    def self.init_and_parse(file)
        obj = RestrictionEnzymeToGene.new
        obj.parse_file_or_die(file)
        obj.motifs
    end

    def initialize
        # parse restriction enzyme sequences. be verbose.
        @motifs = []
        $logger.debug("Parsing restriction enzyme input. Expecting to find sequence motifs.")
    end

    def parse_file_or_die(file)
        @file_info = "#{file} (Attempting to parse restriction enzymes)"
        ensure_file_is_not_empty(file)
        parse_enzymes_and_ensure_enzyme_format(file)

    rescue StandardError => exp
        # something went very wrong. most likely the input file is corrupt.
        ErrorHandling.abort_with_error_message(
            "invalid_enzyme_format", "RestrictionEnzymeToGene", @file_info
        )
    end

    private

    def ensure_file_is_not_empty(file)
        ErrorHandling.abort_with_error_message(
            "empty_file", "RestrictionEnzymeToGene", @file_info
        ) if FileHelper.file_empty?(file)
    end

    def parse_enzymes_and_ensure_enzyme_format(file)
        parse_enzymes(file)
        ensure_enzymes_are_parsed_successfully
    end

    def parse_enzymes(file)
        IO.foreach(file) do |line|
            line = line.chomp
            @motifs.push line unless line.empty?
        end
        @motifs.uniq!
        $logger.debug("Identified #{@motifs.size} restriction enzyme sequences.")
    end

    def ensure_enzymes_are_parsed_successfully
        @motifs.each do |motif|
            unless is_valid_motif(motif)
                $logger.debug("Invalid restriction enzyme: #{motif}")
                ErrorHandling.abort_with_error_message(
                    "invalid_enzyme_format", "RestrictionEnzymeToGene", @file_info
                )
            end
        end
    end

    def is_valid_motif(motif)
        Dna.are_only_valid_nucleotides(motif)
    end
end