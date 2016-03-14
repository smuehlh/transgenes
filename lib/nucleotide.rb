module Nucleotide

    extend self

    def complement(str)
        str.upcase.each_char.map do |char|
            Constants.dna_base_complement.fetch(char)
        end.join("")
    end

    def reverse(str)
        str.reverse
    end

    def reverse_complement(str)
        complement(reverse(str))
    end

end