class Gene
    attr_reader :exons, :introns, :five_prime_utr, :three_prime_utr, :sequence, :description

    def initialize
        @description = ""
        @exons = []
        @introns = []
        @five_prime_utr = "" # exons and introns merged
        @three_prime_utr = "" # exons and introns merged

        @sequence = "" # UTRs, exons and introns merged together

        @ese_motifs = []
    end

    def add_cds(exons, introns, gene_name)
        @exons = exons
        @introns = introns
        @description = gene_name

        @sequence = combine_features_to_sequence
    end

    def add_five_prime_utr(exons, introns, dummy)
        @five_prime_utr = combine_exons_and_introns(exons, introns)
        @sequence = combine_features_to_sequence
    end

    def add_three_prime_utr(exons, introns, dummy)
        @three_prime_utr = combine_exons_and_introns(exons, introns)
        @sequence = combine_features_to_sequence
    end

    def add_ese_list(ese_motifs)
        @ese_motifs = ese_motifs
    end

    def remove_introns(is_remove_first_intron)
        @introns = is_remove_first_intron ? [] : [@introns.first]
        @sequence = combine_features_to_sequence
    end

    def print_statistics
        str = "Number of exons: #{@exons.size}"
        first_intron_kept = @introns.size == 1
        str += "\nAll introns " + (first_intron_kept ? "but" : "including") + " the first removed."
        str += "\nTotal mRNA size: #{@sequence.size}"
        str
    end

    def tweak_sequence(options)
        is_replaced_any_codons = false
        scorer = ScoreSynonymousCodons.new(@exons, @ese_motifs)
        syn_sites = SynonymousSites.new(@exons, @introns)

        syn_sites.get_synonymous_sites_in_exons.each do |pos|
            ranked_synonymous_codons = scorer.score_synonymous_codons_at(pos)
            best_scoring_codon = ranked_synonymous_codons.first

            if scorer.is_codon_not_the_original(best_scoring_codon)
                replace_codon_at_pos(pos, best_scoring_codon)
                is_replaced_any_codons = true
            end
        end

        ErrorHandling.warn_with_error_message(
            "no_codons_replaced") unless is_replaced_any_codons

        # combine sequences
        @sequence = combine_features_to_sequence
    end

    private

    def combine_features_to_sequence
        [
            @five_prime_utr,
            combine_exons_and_introns(@exons, @introns),
            @three_prime_utr
        ].join("")
    end

    def combine_exons_and_introns(exons, introns)
        exons.zip(introns).flatten.compact.join("")
    end

    def replace_codon_at_pos(pos, new_codon)
        @exons.each do |exon|
            if pos >= exon.size
                pos -= exon.size
            else
                exon[pos] = new_codon.chars.last
                break
            end
            exon
        end
    end
end