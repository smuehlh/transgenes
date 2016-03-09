class Gene

    def initialize(file)
        @path = file
        @translation = ""
        @description = []
        @exons = []
        @introns = []

        parse_file

    end

    def parse_file
        if ! is_valid_file_extension
            abort "Unrecognized file format: #{@path}.\n"\
                "Input has to be either a GeneBank record or "\
                "a FASTA file containing exons and introns."
        end

        #  reached this line? must be a valid file extension
        input_data = if FileHelper.get_file_extension(@path) == ".gb"
                        GenebankToGene.new(@path)
                    else
                        # must be fasta, as this is the only other allowed file format
                        FastaToGene.new(@path)
                    end
        @translation = input_data.translation
        @description = input_data.description
        @exons = input_data.exons
        @introns = input_data.introns

    end

    def tweak_exons

    end

    private

    def is_valid_file_extension
        case FileHelper.get_file_extension(@path)
        when ".gb"
            true
        when ".fas", ".fa", ".fasta"
            true
        else
            false
        end
    end
end
