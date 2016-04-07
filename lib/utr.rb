class Utr

    def initialize(file, use_gene_starting_in_line, utr_type)
        init_utr_features
        # INFO class might have been called with a non-existing file
        if file
            parse_utr_file(file, use_gene_starting_in_line, utr_type)
            save_features
        end
    end

    def get_sequence
        @exons.zip(@introns).flatten.join("")
    end

    private

    def init_utr_features
        @exons = []
        @introns = []
    end

    def parse_utr_file(file, use_gene_starting_in_line, utr_type)
        @to_gene_obj = ToGene.new()
        @to_gene_obj.parse_file_to_utr_data_or_die(
            file, use_gene_starting_in_line, utr_type
        )
    end

    def save_features
        @exons = @to_gene_obj.exons
        @introns = @to_gene_obj.introns
    end
end