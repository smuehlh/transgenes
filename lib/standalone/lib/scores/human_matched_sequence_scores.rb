class HumanMatchedSequenceScores

    def initialize
    end

    def score(synonymous_codons, dummy)
        synonymous_codons.collect do |synonymous_codon|
            actual_score(synonymous_codon)/max_score(synonymous_codons).to_f
        end
    end

    private

    def actual_score(synonymous_codon)
        human_codon_usage[synonymous_codon]
    end

    def max_score(synonymous_codons)
        synonymous_codons.inject(0){|sum, codon| sum + human_codon_usage[codon]}
    end

    def human_codon_usage
        # fraction of codons being X
        {
            "TTT" => 0.46, "TTC" => 0.54,
            "TTA" => 0.08, "TTG" => 0.13, "CTT" => 0.13, "CTC" => 0.2, "CTA" => 0.07, "CTG" => 0.4,
            "ATT" => 0.36, "ATC" => 0.47, "ATA" => 0.17,
            "ATG" => 1.0,
            "GTT" => 0.18, "GTC" => 0.24, "GTA" => 0.12, "GTG" => 0.46,
            "TCT" => 0.19, "TCC" => 0.22, "TCA" => 0.15, "TCG" => 0.05, "AGT" => 0.15, "AGC" => 0.24,
            "CCT" => 0.29, "CCC" => 0.32, "CCA" => 0.28, "CCG" => 0.11,
            "ACT" => 0.25, "ACC" => 0.36, "ACA" => 0.28, "ACG" => 0.11,
            "TAT" => 0.44, "TAC" => 0.56,
            "GCT" => 0.27, "GCC" => 0.4, "GCA" => 0.23, "GCG" => 0.11,
            "CAT" => 0.42, "CAC" => 0.58,
            "CAA" => 0.27, "CAG" => 0.73,
            "AAT" => 0.47, "AAC" => 0.53,
            "AAA" => 0.43, "AAG" => 0.57,
            "GAT" => 0.46, "GAC" => 0.54,
            "GAA" => 0.42, "GAG" => 0.58,
            "TGT" => 0.46, "TGC" => 0.54,
            "TGG" => 1.0,
            "CGT" => 0.08, "CGC" => 0.18, "CGA" => 0.11, "CGG" => 0.2, "AGA" => 0.21, "AGG" => 0.21,
            "GGT" => 0.16, "GGC" => 0.34, "GGA" => 0.25, "GGG" => 0.25,
            "TAA" => 0.3, "TAG" => 0.24, "TGA" => 0.47
        }
    end
end