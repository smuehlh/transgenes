class Gene

    def initialize(file)
        @path = file

        # parse file and set variables describing gene
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
        data_obj = if FileHelper.get_file_extension(@path) == ".gb"
                        GenebankToGene.new(@path)
                    else
                        # must be fasta, as this is the only other allowed file format
                        FastaToGene.new(@path)
                    end
        save_input_data_or_die(data_obj)
    end

    def tweak_exons

    end

    private

    def is_valid_file_extension
        case FileHelper.get_file_extension(@path)
        when GenebankToGene.valid_file_extensions
            true
        when *FastaToGene.valid_file_extensions
            # INFO: * turns array into comma-separated list of strings
            true
        else
            false
        end
    end

    def save_input_data_or_die(to_gene_obj)
        @translation = to_gene_obj.translation
        @description = to_gene_obj.description
        @exons = to_gene_obj.exons
        @introns = to_gene_obj.introns

        # ensure file format
        abort "Unrecognized file format: #{@path}.\n"\
            "Input has to be either a GeneBank record or "\
            "a FASTA file containing exons and introns."\
            if ! are_exons_and_introns_found

        abort "Invalid gene format: #{@path}.\n"\
            "There should be one exon more than introns."\
            if ! are_exons_and_introns_numbers_matching_specification

        abort "Nothing to do: #{@path}.\n"\
            "Must leave all #{n_exons()} exons intact."\
            if ! is_minimum_number_exons_given

        abort "Invalid gene format: \n"\
            "Specified translation does not match translated exons."\
            if ! is_given_translation_and_exons_translation_same
    end

    def are_exons_and_introns_found
        # check file format the duck-typing way...
        # a proper genebank/fasta-file specifies a description, exons and introns
        @exons.any? && @introns.any? && @description != ""
    end

    def are_exons_and_introns_numbers_matching_specification
        # check file format the duck-typing way...
        # a proper gene has at least one exon to tweak
        # and is of format: exon-intron[-exon-intron]*-exon
        n_exons == n_introns + 1
    end

    def is_minimum_number_exons_given
        Constants.minimum_number_of_exons < n_exons
    end

    def is_given_translation_and_exons_translation_same
        ToGene.translate_exons(@exons) == @translation
    end

    def n_exons
        @exons.size
    end

    def n_introns
        @introns.size
    end

end
