class GeneStatistics

    attr_reader :exons, :length

    def initialize(gene_obj)
        @exons = gene_obj.exons.size
        @length = gene_obj.combine_features_into_sequence.size
    end

    def print
        str = "Number of exons: #{@exons}"
        str += "\nTotal mRNA size: #{@length}"
        str
    end
end