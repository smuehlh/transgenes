class EnhancedGene < ActiveRecord::Base
    serialize :gene_variants
    serialize :gc3_over_all_gene_variants

    def reset
        self.update_attributes(
            gene_name: "",
            data: "",
            gene_variants: [],
            gc3_over_all_gene_variants: [],
            log: "",
            strategy: "",
            select_by: "",
            keep_first_intron: false,
            stay_in_subbox_for_6folds: false,
            destroy_ese_motifs: false
        )
    end

    def to_fasta(is_split_seq=true)
        to_fasta_obj = GeneToFasta.new(self.gene_name, self.data, is_split_seq)
        to_fasta_obj.fasta
    end

    def fasta_formatted_synonymous_variants
        self.gene_variants.join("\n")
    end
end