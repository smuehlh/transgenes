class EnhancedGene < ActiveRecord::Base

    def to_fasta
        to_fasta_obj = GeneToFasta.new(self.gene_name, self.data)
        to_fasta_obj.fasta
    end
end