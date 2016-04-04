module AminoAcid

    extend self

    def translate(cdna)
        codons = split_cdna_into_codons(cdna)
        delete_trailing_stopcodon_if_present(codons)
        codons.map do |codon|
            Constants.genetic_code.fetch(codon)
        end.join("")
    end

    def split_cdna_into_codons(cdna)
        cdna.scan(/.{1,3}/)
    end

    def is_invalid_codons(cdna)
        codons = split_cdna_into_codons(cdna)
        (codons - Constants.valid_codons).any?
    end

    def delete_trailing_stopcodon_if_present(codons)
        if is_stopcodon(codons.last)
            codons.pop
        end
    end

    def is_stopcodon(codon)
        Constants.genetic_code.fetch(codon) == "X"
    end

end