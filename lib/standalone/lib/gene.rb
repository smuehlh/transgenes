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
        @number_of_changed_sites = 0
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

    def log_statistics
        str = "Number of exons: #{@exons.size}\n"
        first_intron_kept = @introns.size == 1
        str += "All introns " + (first_intron_kept ? "but" : "including") + " the first removed.\n"
        n_aa = @exons.join("").size / 3
        str += "Number of amino acids: #{n_aa}\n"
        str += "Total mRNA size: #{@sequence.size}"
        $logger.info(str)
    end

    def tweak_sequence(strategy)
        scorer = ScoreSynonymousCodons.new(strategy, @exons, @ese_motifs)
        syn_sites = SynonymousSites.new(@exons, @introns)

        syn_sites.get_synonymous_sites_in_exons.each do |pos|
            ranked_synonymous_codons = scorer.score_synonymous_codons_at(pos)
            best_scoring_codon = ranked_synonymous_codons.first

            if scorer.is_codon_not_the_original(best_scoring_codon)
                replace_codon_at_pos(pos, best_scoring_codon)
                @number_of_changed_sites += 1
                $logger.info(scorer.log_changes)
            end
        end

        # combine sequences
        @sequence = combine_features_to_sequence
    end

    def log_tweak_statistics
        $logger.info("Changed #{@number_of_changed_sites} synonymous sites.")
        ErrorHandling.warn_with_error_message(
            "no_codons_replaced", "Gene"
        ) if @number_of_changed_sites == 0
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