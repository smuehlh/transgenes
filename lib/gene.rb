class Gene

    def initialize(file, line)
        @path = file
        @use_gene_starting_in_line = line # nil if none was specified

        # parse file and set variables describing gene
        @translation = ""
        @description = []
        @exons = []
        @introns = []
        parse_file
    end

    def parse_file

        abort "Unrecognized file format: #{@path}.\n"\
            "Input has to be either a GeneBank record or "\
            "a FASTA file containing exons and introns."\
            if ! is_valid_file_extension

        #  reached this line? must be a valid file extension
        data_obj =  if FileHelper.get_file_extension(@path) == ".gb"
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
        description, exons, introns, translation =  reduce_data_to_single_gene_or_die(to_gene_obj)

        save_description_or_die(description)
        save_exons_and_introns_or_die(exons, introns)
        save_or_generate_translation_or_die(translation)
    end

    def reduce_data_to_single_gene_or_die(to_gene_obj)
        gene_starts = to_gene_obj.genestart_lines

        valid_gene_start_info = ToGene.format_gene_descriptions_line_numbers_for_printing(
                to_gene_obj.descriptions.values,
                gene_starts
            )
        abort_message_missing_gene_start =
            "Multiple genes found in file: #{@path}\n"\
            "#{valid_gene_start_info}\n"\
            "Specify gene of interest using argument --line <starting-line>"
        abort_message_invalid_gene_start =
            "Invalid gene-start line specified: #{@use_gene_starting_in_line}\n"\
            "Found genes in lines:\n"\
            "#{valid_gene_start_info}\n"\
            "Specify gene of interest using argument --line <starting-line>"

        wanted_gene_start = if is_single_gene_found(gene_starts)
                                gene_starts.first
                            else
                                if is_gene_start_specified
                                    if is_gene_starting_in_specified_line(gene_starts)
                                        @use_gene_starting_in_line
                                    else
                                        abort abort_message_invalid_gene_start
                                    end
                                else
                                    abort abort_message_missing_gene_start
                                end
                            end

        [
            to_gene_obj.descriptions[wanted_gene_start],
            to_gene_obj.exons[wanted_gene_start],
            to_gene_obj.introns[wanted_gene_start],
            to_gene_obj.translations[wanted_gene_start]
        ]
    end

    def save_description_or_die(description)
        @description = description
    end

    def save_exons_and_introns_or_die(exons, introns)
        @exons = exons
        @introns = introns

        abort "Unrecognized file format: #{@path}.\n"\
            "Cannot find gene entry with exons and introns." if
            ! are_exons_and_introns_found

        abort "Invalid gene format: #{@path}.\n"\
            "There should be one exon more than introns." if
            ! are_exons_and_introns_numbers_matching_specification

        abort "Nothing to do: #{@path}.\n"\
            "Must leave all #{n_exons()} exons intact." if
            ! is_minimum_number_exons_given
    end

    def save_or_generate_translation_or_die(translation)
        @translation = translation || ToGene.translate_exons(@exons)

        abort "Invalid gene format: \n"\
            "Specified translation does not match translated exons." if
            ! is_given_translation_and_exons_translation_same
    end

    def is_single_gene_found(gene_starts)
        gene_starts.size == 1
    end

    def is_gene_start_specified
        @use_gene_starting_in_line
    end

    def is_gene_starting_in_specified_line(gene_starts)
        gene_starts.include?(@use_gene_starting_in_line)
    end

    def are_exons_and_introns_found
        # check file format the duck-typing way...
        # a proper genebank/fasta-file specifies exons and introns
        @exons.any? && @introns.any?
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
