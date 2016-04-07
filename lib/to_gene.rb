class ToGene

    attr_reader :gene_name, :exons, :introns

    def initialize
        @gene_name = ""
        @exons = []
        @introns = []
    end

    def parse_file_to_gene_data_or_die(file, use_gene_starting_in_line)
        # NOTE: init variables along the way.
        ensure_file_format_is_valid(file)
        split_file_into_single_genes_or_die(file)
        ensure_wanted_gene_is_found(use_gene_starting_in_line)
        warn_if_wanted_gene_is_partial(use_gene_starting_in_line)
        parse_wanted_gene_record(use_gene_starting_in_line)
        ensure_gene_is_parsed_successfully

    rescue StandardError => exp
        # something went very wrong. most likely the input file is corrupt.
        ErrorHandling.abort_with_error_message(
            "invalid_file_format", file
        )
    end

    private

    def ensure_file_format_is_valid(file)
        ErrorHandling.abort_with_error_message(
            "invalid_file_format", file
        ) unless is_valid_file_extension(file)
    end

    def split_file_into_single_genes_or_die(file)
        @file = file
        @file_to_gene_obj =
            if is_valid_genebank_file_extension
                GenebankToGene.new(file)
            else
                # must be in fasta-format.
                FastaToGene.new(file)
            end
        @gene_records_by_gene_starts =
            @file_to_gene_obj.split_file_into_single_genes

        ErrorHandling.abort_with_error_message(
            "invalid_file_format", "#{@file}.\nMissing gene record"
        ) unless are_gene_starts_found
    end

    def ensure_wanted_gene_is_found(use_gene_starting_in_line)
        possible_gene_starts = format_list_with_gene_starts
        if use_gene_starting_in_line
            ErrorHandling.abort_with_error_message(
                "invalid_gene_start", possible_gene_starts
            ) unless is_valid_gene_start(use_gene_starting_in_line)
        else
            ErrorHandling.abort_with_error_message(
                "missing_gene_start", possible_gene_starts
            ) unless is_single_gene_record
        end
    end

    def warn_if_wanted_gene_is_partial(use_gene_starting_in_line)
        gene_record = get_wanted_gene_record(use_gene_starting_in_line)
        ErrorHandling.warn_with_error_message(
            "partial_gene"
        ) if @file_to_gene_obj.is_partial_gene(gene_record)
    end

    def parse_wanted_gene_record(use_gene_starting_in_line)
        gene_record = get_wanted_gene_record(use_gene_starting_in_line)
        @file_to_gene_obj.parse_gene_record(gene_record)
        @gene_name = @file_to_gene_obj.gene_name
        @exons = @file_to_gene_obj.exons
        @introns = @file_to_gene_obj.introns
    end

    def ensure_gene_is_parsed_successfully
        ensure_gene_name_is_found
        ensure_exons_and_introns_are_found
        ensure_exons_contain_valid_codons_only
    end

    def ensure_gene_name_is_found
        ErrorHandling.abort_with_error_message(
            "invalid_file_format", "#{@file}.\nMissing gene description"
        ) unless is_gene_description_found
    end

    def ensure_exons_and_introns_are_found
        ErrorHandling.abort_with_error_message(
            "invalid_file_format", "#{@file}.\nMissing or invalid gene record"
        ) unless are_exons_and_introns_found
    end

    def ensure_exons_contain_valid_codons_only
        ErrorHandling.abort_with_error_message(
            "invalid_codons", @file
        ) unless are_codons_valid
    end

    def is_valid_file_extension(file)
        @file_extension = FileHelper.get_file_extension(file)
        is_valid_genebank_file_extension || is_valid_fasta_file_extension
    end

    def is_valid_genebank_file_extension
        GenebankToGene.valid_file_extensions.include?(@file_extension)
    end

    def is_valid_fasta_file_extension
        FastaToGene.valid_file_extensions.include?(@file_extension)
    end

    def are_gene_starts_found
        @gene_records_by_gene_starts.keys.any? &&
            ! @gene_records_by_gene_starts.key?(nil)
    end

    def is_single_gene_record
        @gene_records_by_gene_starts.size == 1
    end

    def is_valid_gene_start(gene_start)
        @gene_records_by_gene_starts.key?(gene_start)
    end

    def is_gene_description_found
        @gene_name != ""
    end

    def are_exons_and_introns_found
        @exons.any? && @exons.join("") != "" && is_gene_with_exons_and_introns
    end

    def is_gene_with_exons_and_introns
        # gene should be of format: exon-intron-[exon-intron]*-exon
        @exons.size == @introns.size + 1
    end

    def are_codons_valid
        ! AminoAcid.is_invalid_codons(@exons.join(""))
    end

    def format_list_with_gene_starts
        @gene_records_by_gene_starts.map do |gene_start, full_gene_record|
            gene_record_start = full_gene_record.first.strip
            gene_record_start = "#{gene_record_start[0..50]} ..." if gene_record_start.size > 50
            "\t#{gene_start}: #{gene_record_start}"
        end.join("\n")
    end

    def first_gene_record
        @gene_records_by_gene_starts.values.first
    end

    def get_wanted_gene_record(use_gene_starting_in_line)
        if use_gene_starting_in_line
            @gene_records_by_gene_starts[use_gene_starting_in_line]
        else
            first_gene_record
        end
    end
end