class EnhancedGene < ActiveRecord::Base
    serialize :gene_variants
    serialize :gc3_over_all_gene_variants
    serialize :gc3_per_individual_variant

    def reset
        self.update_attributes(
            gene_name: "",
            data: "",
            gene_variants: [],
            gc3_over_all_gene_variants: [],
            gc3_per_individual_variant: [],
            log: "",
            strategy: "",
            select_by: "",
            ese_strategy: "",
            keep_first_intron: false,
            stay_in_subbox_for_6folds: false,
            destroy_ese_motifs: false,
            score_eses_at_all_sites: false,
            keep_restriction_sites: false,
            avoid_restriction_sites: false
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