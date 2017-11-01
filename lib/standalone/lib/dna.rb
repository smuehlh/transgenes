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

    def are_only_valid_nucleotides(str)
        nucleotides = str.chars
        (nucleotides - valid_nucleotides).empty?
    end

    def reverse(str)
        str.reverse
    end

    def reverse_complement(str)
        complement(reverse(str))
    end

    def complement(str)
        str.upcase.each_char.map do |char|
            base_complement.fetch(char)
        end.join("")
    end
end