class EseToGene

    attr_reader :motifs

    def self.init_and_parse(file)
        obj = EseToGene.new
        obj.parse_file_or_die(file)
        obj.motifs
    end

    def initialize
        # parse ESEs. be verbose.
        @motifs = []
        $logger.info("Parsing ESE input. Expecting to find motifs.")
    end

    def parse_file_or_die(file)
        @file_info = "#{file} (Attempting to parse ESEs)"
        ensure_file_is_not_empty(file)
        parse_eses_and_ensure_ese_format(file)

    rescue StandardError => exp
        # something went very wrong. most likely the input file is corrupt.
        ErrorHandling.abort_with_error_message(
            "invalid_ese_format", "EseToGene", @file_info
        )
    end

    private

    def ensure_file_is_not_empty(file)
        ErrorHandling.abort_with_error_message(
            "empty_file", "ToGene", @file_info
        ) if FileHelper.file_empty?(file)
    end

    def parse_eses_and_ensure_ese_format(file)
        parse_eses(file)
        ensure_eses_are_parsed_successfully
    end

    def parse_eses(file)
        IO.foreach(file) do |line|
            line = line.chomp
            @motifs.push line
        end
        $logger.info("Identified #{@motifs.size} motifs.")
    end

    def ensure_eses_are_parsed_successfully
        @motifs.each do |motif|
            unless is_valid_motif(motif)
                $logger.info("Invalid motif: #{motif}")
                ErrorHandling.abort_with_error_message(
                    "invalid_ese_format", "EseToGene", @file_info
                )
            end
        end
    end

    def is_valid_motif(motif)
        motif.size == 6 && Dna.are_only_valid_nucleotides(motif)
    end
end