class ToGene

    attr_reader :gene_name, :exons, :introns

    def initialize
        @gene_name = ""
        @exons = []
        @introns = []
    end

    def parse_file_to_gene_data_or_die(file, use_gene_starting_in_line)
        @file_info = file

        # NOTE: init variables along the way.
        ensure_file_format_is_valid(file)
        init_file_to_gene_obj("CDS")
        split_file_into_single_features_or_die
        ensure_wanted_feature_is_found(use_gene_starting_in_line)
        warn_if_wanted_gene_is_partial(use_gene_starting_in_line)
        parse_wanted_feature_record(use_gene_starting_in_line)
        ensure_gene_is_parsed_successfully

    rescue StandardError => exp
        # something went very wrong. most likely the input file is corrupt.
        ErrorHandling.abort_with_error_message(
            "invalid_file_format", @file_info
        )
    end

    def parse_file_to_utr_data_or_die(file, use_utr_starting_in_line, utr_type)
        @file_info = "#{file} (Attempting to parse #{utr_type})"

        # NOTE: init variables along the way.
        ensure_file_format_is_valid(file)
        init_file_to_gene_obj(utr_type)
        split_file_into_single_features_or_die
        ensure_wanted_feature_is_found(use_utr_starting_in_line)
        parse_wanted_feature_record(use_utr_starting_in_line)
        ensure_utr_is_parsed_successfully

    rescue StandardError => exp
        # something went very wrong. most likely the input file is corrupt.
        ErrorHandling.abort_with_error_message(
            "invalid_file_format", @file_info
        )
    end

    private

    # NOTE:
    # method defined here indicate if the apply to genes or utrs or both.
    # methods defined in file_to_gene apply to both, even if termed "gene".

    def ensure_file_format_is_valid(file)
        ErrorHandling.abort_with_error_message(
            "invalid_file_format", @file_info
        ) unless is_valid_file_extension(file)
    end

    def split_file_into_single_features_or_die
        @feature_records_by_feature_starts =
            @file_to_gene_obj.split_file_into_single_genes

        ErrorHandling.abort_with_error_message(
            "invalid_file_format", "#{@file_info}.\nMissing gene record"
        ) unless are_feature_starts_found
    end

    def ensure_wanted_feature_is_found(use_feature_starting_in_line)
        possible_feature_starts = format_list_with_feature_starts
        if use_feature_starting_in_line
            ErrorHandling.abort_with_error_message(
                "invalid_gene_start", possible_feature_starts
            ) unless is_valid_feature_start(use_feature_starting_in_line)
        else
            ErrorHandling.abort_with_error_message(
                "missing_gene_start", possible_feature_starts
            ) unless is_single_feature_record
        end
    end

    def warn_if_wanted_gene_is_partial(use_gene_starting_in_line)
        gene_record = get_wanted_feature_record(use_gene_starting_in_line)
        ErrorHandling.warn_with_error_message(
            "partial_gene"
        ) if @file_to_gene_obj.is_partial_gene(gene_record)
    end

    def parse_wanted_feature_record(use_feature_starting_in_line)
        record = get_wanted_feature_record(use_feature_starting_in_line)
        @file_to_gene_obj.parse_gene_record(record)
        save_features
    end

    def ensure_gene_is_parsed_successfully
        ensure_gene_name_is_found
        ensure_exons_and_introns_are_found
        ensure_exons_contain_valid_codons_only
    end

    def ensure_utr_is_parsed_successfully
        # NOTE: don't test if exons can be translated, they might not and there's no need for them to be.
        ensure_gene_name_is_found
        ensure_exons_and_introns_are_found
    end

    def init_file_to_gene_obj(use_genebank_feature)
        @file_to_gene_obj =
            if is_valid_genebank_file_extension
                GenebankToGene.new(@file, use_genebank_feature)
            else
                # must be in fasta-format.
                FastaToGene.new(@file)
            end
    end

    def ensure_gene_name_is_found
        ErrorHandling.abort_with_error_message(
            "invalid_file_format", "#{@file_info}.\nMissing gene description"
        ) unless is_gene_description_found
    end

    def ensure_exons_and_introns_are_found
        ErrorHandling.abort_with_error_message(
            "invalid_file_format",
            "#{@file_info}.\nMissing or invalid gene record"
        ) unless are_exons_and_introns_found
    end

    def ensure_exons_contain_valid_codons_only
        ErrorHandling.abort_with_error_message(
            "invalid_codons", @file_info
        ) unless are_codons_valid
    end

    def save_features
        @gene_name = @file_to_gene_obj.gene_name
        @exons = @file_to_gene_obj.exons
        @introns = @file_to_gene_obj.introns
    end

    def is_valid_file_extension(file)
        @file = file
        @file_extension = FileHelper.get_file_extension(file)
        is_valid_genebank_file_extension || is_valid_fasta_file_extension
    end

    def is_valid_genebank_file_extension
        GenebankToGene.valid_file_extensions.include?(@file_extension)
    end

    def is_valid_fasta_file_extension
        FastaToGene.valid_file_extensions.include?(@file_extension)
    end

    def are_feature_starts_found
        @feature_records_by_feature_starts.keys.any? &&
            ! @feature_records_by_feature_starts.key?(nil)
    end

    def is_single_feature_record
        @feature_records_by_feature_starts.size == 1
    end

    def is_valid_feature_start(feature_start)
        @feature_records_by_feature_starts.key?(feature_start)
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

    def format_list_with_feature_starts
        @feature_records_by_feature_starts.map do |start, full_record|
            first_line = full_record.first.strip
            first_line = "#{first_line[0..50]} ..." if first_line.size > 50
            "\t#{start}: #{first_line}"
        end.join("\n")
    end

    def first_feature_record
        @feature_records_by_feature_starts.values.first
    end

    def get_wanted_feature_record(use_feature_starting_in_line)
        if use_feature_starting_in_line
            @feature_records_by_feature_starts[use_feature_starting_in_line]
        else
            first_feature_record
        end
    end
end