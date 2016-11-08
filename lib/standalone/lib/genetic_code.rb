module GeneticCode

    extend self

    # NOTE: any changes - change reverse_table accordingly
    def table
        {
            "TTT" => "F", "TTC" => "F",
            "TTA" => "L", "TTG" => "L", "CTT" => "L", "CTC" => "L",
                "CTA" => "L", "CTG" => "L",
            "ATT" => "I", "ATC" => "I", "ATA" => "I",
            "ATG" => "M",
            "GTT" => "V", "GTC" => "V", "GTA" => "V", "GTG" => "V",
            "TCT" => "S", "TCC" => "S", "TCA" => "S", "TCG" => "S",
                "AGT" => "S", "AGC" => "S",
            "CCT" => "P", "CCC" => "P", "CCA" => "P", "CCG" => "P",
            "ACT" => "T", "ACC" => "T", "ACA" => "T", "ACG" => "T",
            "TAT" => "Y", "TAC" => "Y",
            "GCT" => "A", "GCC" => "A", "GCA" => "A", "GCG" => "A",
            "CAT" => "H", "CAC" => "H",
            "CAA" => "Q", "CAG" => "Q",
            "AAT" => "N", "AAC" => "N",
            "AAA" => "K", "AAG" => "K",
            "GAT" => "D", "GAC" => "D",
            "GAA" => "E", "GAG" => "E",
            "TGT" => "C", "TGC" => "C",
            "TGG" => "W",
            "CGT" => "R", "CGC" => "R", "CGA" => "R", "CGG" => "R",
                "AGA" => "R", "AGG" => "R",
            "GGT" => "G", "GGC" => "G", "GGA" => "G", "GGG" => "G",
            "TAA" => "*", "TAG" => "*", "TGA" => "*"
        }
    end

    def reverse_table
        {
            "F" => ["TTT", "TTC"],
            "L" => ["CTT", "CTC", "CTA", "CTG", "TTA", "TTG"],
            "I" => ["ATT", "ATC", "ATA"],
            "M" => ["ATG"],
            "V" => ["GTT", "GTC", "GTA", "GTG"],
            "S" => ["TCT", "TCC", "TCA", "TCG", "AGT", "AGC"],
            "P" => ["CCT", "CCC", "CCA", "CCG"],
            "T" => ["ACT", "ACC", "ACA", "ACG"],
            "Y" => ["TAT", "TAC"],
            "A" => ["GCT", "GCC", "GCA", "GCG"],
            "H" => ["CAT", "CAC"],
            "Q" => ["CAA", "CAG"],
            "N" => ["AAT", "AAC"],
            "K" => ["AAA", "AAG"],
            "D" => ["GAT", "GAC"],
            "E" => ["GAA", "GAG"],
            "C" => ["TGT", "TGC"],
            "W" => ["TGG"],
            "R" => ["CGT", "CGC", "CGA", "CGG", "AGA", "AGG"],
            "G" => ["GGT", "GGC", "GGA", "GGG"],
            "*" => ["TAA", "TAG", "TGA"]
        }
    end

    def valid_codons
        table.keys
    end

    def is_stopcodon(codon)
        table.fetch(codon, "") == "*"
    end

    def translate(cdna)
        codons = split_cdna_into_codons(cdna)
        delete_trailing_stopcodon_if_present(codons)
        codons.map do |codon|
            table.fetch(codon).upcase
        end.join("")
    end

    def split_cdna_into_codons(cdna)
        cdna.scan(/.{1,3}/)
    end

    def find_invalid_codons(cdna)
        codons = split_cdna_into_codons(cdna)
        codons - valid_codons
    end

    def delete_trailing_stopcodon_if_present(codons)
        if is_stopcodon(codons.last)
            codons.pop
        end
    end

    def get_synonymous_codons(codon)
        transl = table.fetch(codon)
        reverse_table.fetch(transl, [])
    end

    def get_synonymous_codons_in_codon_box(codon)
        syn_codons = get_synonymous_codons(codon)
        syn_codons.select{ |syn_codon| syn_codon.start_with?(codon[0]) }
    end

    def get_codons_same_third_site_and_degeneracy(codon)
        if is_stopcodon(codon)
            return [codon]
        else
            syn_codons = get_synonymous_codons(codon)
            syn_codons_same_box = get_synonymous_codons_in_codon_box(codon)
            valid_codons.collect do |other|
                next if other[-1] != codon[-1]
                next if get_synonymous_codons(other).size != syn_codons.size
                next if get_synonymous_codons_in_codon_box(other).size != syn_codons_same_box.size

                other
            end.compact
        end
    end
end