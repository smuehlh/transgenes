module Dna

    extend self

    def base_complement
        {
            "A" => "T",
            "T" => "A",
            "C" => "G",
            "G" => "C"
        }
    end

    def valid_nucleotides
        base_complement.keys
    end

    def reverse(str)
        str.reverse
    end

    def reverse_complement(str)
        complement(reverse(str))
    end

    def remove_invalid_chars(str)
        valid_char_regexp = valid_nucleotides.join("")
        str.regexp_delete(/[^#{valid_char_regexp}]/i)
    end

    def complement(str)
        str.upcase.each_char.map do |char|
            base_complement.fetch(char)
        end.join("")
    end
end