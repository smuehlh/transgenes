class ToGene

    def read_file(path)
        # implement in sub-class
    end

    def self.valid_file_extensions
        # implement in sub-class
    end

    def translate_exons(exons)
        joined_exons = exons.join("")
        AminoAcid.translate(joined_exons)
    end

    def ensure_exon_translation_matches_given_translation(exons, translation)
        if translate_exons(exons) != translation
            abort "Invalid gene format: Specified translation does not match translated exons."
        end
    end

    def convert_exons_to_uppercase_and_introns_to_lowercase(exons, introns)
        exons.map!{ |e| e.upcase }
        introns.map!{ |i| i.downcase }
    end

end