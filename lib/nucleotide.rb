module Nucleotide

    extend self

    def remove_invalid_chars(str)
        valid_char_regexp = Constants.valid_nucleotides.join("")
        str.regexp_delete(/[^#{valid_char_regexp}]/i)
    end

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