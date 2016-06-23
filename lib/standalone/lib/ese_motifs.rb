class EseToGene

    attr_reader :motifs

    def self.init_and_parse(file)
        obj = EseToGene.new
        obj.parse_file_or_die(file)
        [obj.motifs]
    end

    def initialize
        @motifs = []
    end

    def parse_file_or_die(file)
        @file_info = "#{file} (Attempting to parse ESEs)"
        parse_eses_and_ensure_ese_format(file)

    rescue StandardError => exp
        # something went very wrong. most likely the input file is corrupt.
        ErrorHandling.abort_with_error_message(
            "invalid_ese_format", @file_info
        )
    end

    private

    def parse_eses_and_ensure_ese_format(file)
        parse_eses(file)
        ensure_eses_are_parsed_successfully
    end

    def parse_eses(file)
        IO.foreach(file) do |line|
            line = line.chomp
            @motifs.push line
        end
    end

    def ensure_eses_are_parsed_successfully
        @motifs.each do |motif|
            ErrorHandling.abort_with_error_message(
                "invalid_ese_format", @file_info
            ) unless is_valid_motif(motif)
        end
    end

    def is_valid_motif(motif)
        motif.size == 6 && Dna.are_only_valid_nucleotides(motif)
    end
end