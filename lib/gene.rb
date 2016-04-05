class Gene

    def initialize(file, use_gene_starting_in_line)
        to_gene_obj = ToGene.new()
        to_gene_obj.parse_file_to_gene_data_or_die(file,use_gene_starting_in_line)
        save_gene_to_class_variables(to_gene_obj)
    end

    def destroy_ese_sequences
        # only if minimum number of exons found.
    end

    def humanize_codon_usage

    end

    def remove_unwanted_introns
        # only if minimum number of exons found.
        # remove intron and change corresponding splice site
    end

    private

    def save_gene_to_class_variables(to_gene_obj)
        @description = to_gene_obj.gene_name
        @exons = to_gene_obj.exons
        @introns = to_gene_obj.introns
    end
end
