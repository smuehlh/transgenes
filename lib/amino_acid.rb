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
        codons = cdna.scan(/.{1,3}/)
        ensure_codons_can_be_translated(codons)

        codons
    end

    def ensure_codons_can_be_translated(codons)
        # ensure all codons can be translated into amino acid!
        if codons.size == 0
            abort "Cannot translate cDNA: empty sequence."
        end

        if codons.last.size != 3
            abort "Cannot translate cDNA: last codon is splitted."
        end

        invalid_codons = codons - Constants.genetic_code.keys
        if invalid_codons.any?
            abort "Cannot translate cDNA: found invalid codons #{invalid_codons.join(", ")}."
        end

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