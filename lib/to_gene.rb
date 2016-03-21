class ToGene

    def read_file(path)
        # implement in sub-class
    end

    def convert_exons_to_uppercase_and_introns_to_lowercase(exons, introns)
        exons.map!{ |e| e.upcase }
        introns.map!{ |i| i.downcase }
    end

    def self.valid_file_extensions
        # implement in sub-class
    end

    def self.format_gene_descriptions_line_numbers_for_printing(descriptions, additional_infos, lines)
        descriptions.map.each_with_index do |desc, ind|
            line = lines[ind]
            add_info = if str = additional_infos[ind]
                "(#{str})"
            else
                ""
            end
            "\tline #{line}: #{desc} #{add_info}\n"
        end.join("")
    end

    def self.translate_exons(exons)
        joined_exons = exons.join("")
        AminoAcid.translate(joined_exons)
    end

end