class EnsemblGene < ActiveRecord::Base

    # to be used in validation, including in client-side validation.
    # values will be attached to corresponding input-elements
    MAX_LENGTH_GENEID = 40
    FORMAT_GENEID_BASE = 'ENST\d+(?:\.\d+)?'
    FORMAT_GENEID_RAILS = "\\A#{FORMAT_GENEID_BASE}\\z"
    FORMAT_GENEID_WEB = "^#{FORMAT_GENEID_BASE}$"

    validates_presence_of :cds
    validates :gene_id,
        uniqueness: true,
        length: { maximum: MAX_LENGTH_GENEID },
        format: { with: /#{FORMAT_GENEID_RAILS}/ }

    def self.import(id, seq, utr5, utr3, version)
        create(gene_id: id, cds: seq, utr5: utr5, utr3: utr3, version: version)
    end

    def to_fasta(kind="CDS")
        to_fasta_obj =
            if kind == "5'UTR"
                GeneToFasta.new(self.gene_id, self.utr5)
            elsif kind == "3'UTR"
                GeneToFasta.new(self.gene_id, self.utr3)
            else
                GeneToFasta.new(self.gene_id, self.cds)
            end
        to_fasta_obj.fasta
    end
end
