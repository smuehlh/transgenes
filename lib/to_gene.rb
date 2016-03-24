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
        split_file_into_single_genes(file)
        ensure_wanted_gene_is_found(use_gene_starting_in_line)
        warn_if_wanted_gene_is_partial(use_gene_starting_in_line)
        parse_wanted_gene_record(use_gene_starting_in_line)
        ensure_gene_is_parsed_successfully
    end

    private

    def ensure_file_format_is_valid(file)
        ErrorHandling.abort_with_error_message(
            "invalid_file_format", file
        ) unless is_valid_file_extension(file)
    end

    def split_file_into_single_genes(file)
        @file_to_gene_obj =
            if is_valid_genebank_file_extension
                GenebankToGene.new(file)
            else
                # must be in fasta-format.
                FastaToGene.new(file)
            end
        @gene_records_by_gene_starts =
            @file_to_gene_obj.split_file_into_single_genes
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
        @gene_name, @exons, @introns = @file_to_gene_obj.parse_gene_record(gene_record)
    end

    def ensure_gene_is_parsed_successfully
        # TODO
        # error handling: gene_name present, exons & introns present & in correct format, ...
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

    def is_single_gene_record
        @gene_records_by_gene_starts.size == 1
    end

    def is_valid_gene_start(gene_start)
        @gene_records_by_gene_starts.key?(gene_start)
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