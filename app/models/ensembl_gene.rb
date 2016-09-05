class EnsemblGene < ActiveRecord::Base

    def self.import(ids, seqs, version)
        ids.each_with_index do |id, ind|
            seq = seqs[ind]
            create(sequence: seq, gene_id: id, version: version)
        end
    end
end
