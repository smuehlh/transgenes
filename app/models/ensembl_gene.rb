class EnsemblGene < ActiveRecord::Base

    # to be used in validation, including in client-side validation.
    # values will be attached to corresponding input-elements
    MAX_LENGTH_GENEID = 40
    FORMAT_GENEID_BASE = 'ENSG\d+(?:\.\d+)?'
    FORMAT_GENEID_RAILS = "\\A#{FORMAT_GENEID_BASE}\\z"
    FORMAT_GENEID_WEB = "^#{FORMAT_GENEID_BASE}$"

    validates_presence_of :sequence
    validates :gene_id,
        uniqueness: true,
        length: { maximum: MAX_LENGTH_GENEID },
        format: { with: /#{FORMAT_GENEID_RAILS}/ }

    def self.import(ids, seqs, version)
        ids.each_with_index do |id, ind|
            seq = seqs[ind]
            create(sequence: seq, gene_id: id, version: version)
        end
    end
end
