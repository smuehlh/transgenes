module AminoAcid

    extend self


    def translate(cdna)
        codons = split_cdna_into_codons(cdna)
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

        non_codons = codons - Constants.genetic_code.keys
        if non_codons.any?
            abort "Cannot translate cDNA: unrecognized codons: #{non_codons}."
        end

    end

end