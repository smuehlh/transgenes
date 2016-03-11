class ToGene

    def read_file(path)
        # implement in sub-class
    end

    def translate_exons(exons)
        joined_exons = exons.join("")
        AminoAcid.translate(joined_exons)
    end

    def ensure_exon_translation_matches_given_translation(exons, translation)
        if translate_exons(exons) != translate_exons(exons)
            abort "Invalid gene format: Specified translation does not match translated exons."
        end
    end

    def convert_to_uppercase(arr)
        arr.map{ |e| e.upcase }
    end

end