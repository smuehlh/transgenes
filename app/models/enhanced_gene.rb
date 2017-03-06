class EnhancedGene < ActiveRecord::Base

    def reset
        self.update_attributes(
            gene_name: "",
            data: "",
            gene_variants: "",
            log: "",
            strategy: "",
            select_by: "",
            keep_first_intron: false
        )
    end

    def to_fasta(is_split_seq=true)
        to_fasta_obj = GeneToFasta.new(self.gene_name, self.data, is_split_seq)
        to_fasta_obj.fasta
    end
end