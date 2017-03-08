class EnhancedGene < ActiveRecord::Base

    def reset
        self.update_attributes(
            gene_name: "",
            data: "",
            log: "",
            strategy: "",
            select_by: "",
            keep_first_intron: false,
            destroy_ese_motifs: false
        )
    end

    def to_fasta
        to_fasta_obj = GeneToFasta.new(self.gene_name, self.data)
        to_fasta_obj.fasta
    end
end