class ToGene

    attr_reader :gene_name, :exons, :introns

    def self.init_and_parse(use_feature, file, use_feature_starting_in_line)
        obj = ToGene.new(use_feature)
        obj.parse_file_or_die(file, use_feature_starting_in_line)
        [obj.exons, obj.introns, obj.gene_name]
    end

    def initialize(use_feature)
        # parse genes. be verbose.
        @gene_name = ""
        @exons = []
        @introns = []

        @use_feature = use_feature
    end

    def parse_file_or_die(file, use_feature_starting_in_line)
        @file_info = "#{file} (Attempting to parse #{@use_feature})"

        # NOTE: init variables along the way.
        ensure_file_format_and_split_file_into_features(file)
        parse_feature_and_ensure_feature_format(use_feature_starting_in_line)

    rescue StandardError => exp
        # something went very wrong. most likely the input file is corrupt.
        ErrorHandling.abort_with_error_message(
            "invalid_file_format", "ToGene", @file_info
        )
    end

    private

    # NOTE:
    # method names indicate if the apply to both genes and utrs or to genes only.

    def ensure_file_format_and_split_file_into_features(file)
        ensure_file_format_is_valid(file)
        init_file_to_gene_obj
        split_file_into_single_features_or_die
    end

    def parse_feature_and_ensure_feature_format(use_feature_starting_in_line)
        ensure_wanted_feature_is_found(use_feature_starting_in_line)
        parse_wanted_feature_record(use_feature_starting_in_line)
        ensure_feature_is_parsed_successfully

        if is_cds_feature
            warn_if_wanted_gene_is_partial(use_feature_starting_in_line)
            ensure_feature_is_valid_cds
        end
    end

    def ensure_file_format_is_valid(file)
        ensure_file_extension_is_valid(file)
        ensure_file_is_not_empty(file)
    end

    def ensure_file_extension_is_valid(file)
        ErrorHandling.abort_with_error_message(
            "invalid_file_format", "ToGene", @file_info
        ) unless is_valid_file_extension(file)
    end

    def ensure_file_is_not_empty(file)
        ErrorHandling.abort_with_error_message(
            "empty_file", "ToGene", @file_info
        ) if FileHelper.file_empty?(file)
    end

    def split_file_into_single_features_or_die
        @feature_records_by_feature_starts =
            @file_to_gene_obj.split_file_into_single_genes

        ErrorHandling.abort_with_error_message(
            "invalid_file_format", "ToGene", @file_info
        ) unless are_feature_starts_found
    end

    def ensure_wanted_feature_is_found(use_feature_starting_in_line)
        possible_feature_starts = format_list_with_feature_starts
        if use_feature_starting_in_line
            ErrorHandling.abort_with_error_message(
                "invalid_gene_start", "ToGene", possible_feature_starts
            ) unless is_valid_feature_start(use_feature_starting_in_line)
        else
            ErrorHandling.abort_with_error_message(
                "missing_gene_start", "ToGene", possible_feature_starts
            ) unless is_single_feature_record
        end
    end

    def warn_if_wanted_gene_is_partial(use_gene_starting_in_line)
        gene_record = get_wanted_feature_record(use_gene_starting_in_line)
        ErrorHandling.warn_with_error_message(
            "partial_gene", "ToGene"
        ) if @file_to_gene_obj.is_partial_gene(gene_record)
    end

    def parse_wanted_feature_record(use_feature_starting_in_line)
        record = get_wanted_feature_record(use_feature_starting_in_line)
        @file_to_gene_obj.parse_gene_record(record)
        save_features
        log_features
    end

    def init_file_to_gene_obj
        @file_to_gene_obj =
            if is_valid_genebank_file_extension
                GenebankToGene.new(@file, @use_feature)
            else
                # must be in fasta-format.
                FastaToGene.new(@file)
            end
    end

    def ensure_feature_is_parsed_successfully
        ensure_gene_name_is_found
        ensure_exons_and_introns_are_found
    end

    def ensure_feature_is_valid_cds
        ensure_exons_contain_valid_codons_only
    end

    def ensure_gene_name_is_found
        ErrorHandling.abort_with_error_message(
            "invalid_file_format", "ToGene",
            "#{@file_info}.\nMissing gene description"
        ) unless is_gene_description_found
    end

    def ensure_exons_and_introns_are_found
        ErrorHandling.abort_with_error_message(
            "invalid_file_format", "ToGene",
            "#{@file_info}.\nMissing or invalid gene record"
        ) unless are_exons_and_introns_found
    end

    def ensure_exons_contain_valid_codons_only
        ErrorHandling.abort_with_error_message(
            "invalid_codons", "ToGene", @file_info
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

    def is_cds_feature
        @use_feature == "CDS"
    end

    def are_codons_valid
        invalid_codons = GeneticCode.find_invalid_codons(@exons.join(""))
        no_invalid_codons = invalid_codons.empty?
        $logger.debug("Invalid codon(s): #{invalid_codons.join(", ")}") unless no_invalid_codons
        no_invalid_codons
    end

    def format_list_with_feature_starts
        @feature_records_by_feature_starts.map do |start, full_record|
            "\t#{start} #{truncate_record(full_record)}"
        end.join("\n")
    end

    def truncate_record(full_record)
        first_line = full_record.first.strip
        first_line = "#{first_line[0..50]} ..." if first_line.size > 50
        first_line
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

    def log_features
        msg = prepare_sequence_for_log(@exons)
        $logger.debug msg.empty? ? "Identified exons: -" : "Identified exons:\n#{msg}"
        msg = prepare_sequence_for_log(@introns)
        $logger.debug msg.empty? ? "Identified introns: -" : "Identified introns:\n#{msg}"
    end

    def prepare_sequence_for_log(arr)
        counter = (1..arr.size).to_a.map{|n| "(#{n})"}
        counter.zip(arr).map{|a| a.join(" ")}.join("\n")
    end
end