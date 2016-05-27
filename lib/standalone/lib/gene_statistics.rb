class GeneStatistics

    attr_reader :exons, :length

    def initialize(gene_obj)
        @exons = gene_obj.exons.size
        @first_intron_kept = gene_obj.introns.size == 1
        @length = gene_obj.combine_features_into_sequence.size
    end

    def print
        str = "Number of exons: #{@exons}"
        str += "\nFirst intron is " + (@first_intron_kept ? "kept" : "removed")
        str += "\nTotal mRNA size: #{@length}"
        str
    end
end