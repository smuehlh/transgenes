class EnhancedGene < ActiveRecord::Base

    def to_fasta
        fasta = GeneToFasta.new(self.gene_name, self.data)
        [fasta.header, fasta.sequence]
    end
end