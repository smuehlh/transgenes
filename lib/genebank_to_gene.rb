class GenebankToGene

    attr_reader :translation, :description, :exons, :introns

    def initialize(path)
        @translation = ""
        @description = []
        @exons = []
        @introns = []
    end

end