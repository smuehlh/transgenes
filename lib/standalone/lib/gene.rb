class Gene
    attr_reader :exons, :introns, :ese_motifs, :five_prime_utr, :three_prime_utr, :description

    def initialize
        @description = ""
        @exons = [] # CDS only, excluding UTR's
        @introns = []
        @five_prime_utr = "" # exons and introns merged
        @three_prime_utr = "" # exons and introns merged

        @ese_motifs = []
    end

    def add_cds(exons, introns, gene_name)
        @exons = exons
        @introns = introns
        @description = gene_name
    end

    def add_five_prime_utr(exons, introns, dummy)
        @five_prime_utr = combine_exons_and_introns(exons, introns)
    end

    def add_three_prime_utr(exons, introns, dummy)
        @three_prime_utr = combine_exons_and_introns(exons, introns)
    end

    def add_ese_list(ese_motifs)
        @ese_motifs = ese_motifs
    end

    def remove_introns(is_remove_first_intron)
        @introns = is_remove_first_intron ? [] : [@introns.first]
    end

    def log_statistics
        str = "Number of exons: #{@exons.size}\n"
        first_intron_kept = @introns.size == 1
        str += "All introns " + (first_intron_kept ? "but" : "including") + " the first removed.\n"
        n_aa = cds.size / 3
        str += "Number of amino acids: #{n_aa}\n"
        str += "Total mRNA size: #{sequence.size}"
        $logger.info(str)
    end

    def prepare_for_tweaking(stay_in_subbox_for_6folds)
        # NOTE - keep this method seperate from tweak_sequence():
        # preparation needs to be done only once
        @synonymous_sites = SynonymousSites.new(@exons, @introns, stay_in_subbox_for_6folds)
    end

    def tweak_sequence(strategy)
        scorer = ScoreSynonymousCodons.new(strategy, @synonymous_sites, @ese_motifs)
        init_codon_replacement_log

        @synonymous_sites.all_sites.each do |pos|
            codon = scorer.select_synonymous_codon_at(pos)

            if ! scorer.is_original_codon_selected_at(pos, codon)
                replace_codon_at_pos(pos, codon)
                log_codon_replacement(scorer.log_selected_codon_at(pos, codon))
            end
        end
    end

    def sequence
        # NOTE - can't precalc, as exons might change
        @five_prime_utr + combine_exons_and_introns(@exons, @introns) + @three_prime_utr
    end

    def gc3_content
        gc3_counts = gc3_count_per_synonymous_site
        Statistics.sum(gc3_counts)/gc3_counts.size.to_f
    end

    def gc3_count_per_synonymous_site
        @synonymous_sites.all_sites.collect{|pos| cds[pos].count("GC")}
    end

    def log_changed_sites
        [@number_of_changed_sites, @changed_sites]
    end

    private

    def combine_exons_and_introns(exons, introns)
        exons.zip(introns).flatten.compact.join("")
    end

    def cds
        # NOTE - can't precalc, as exons might change
        @exons.join("")
    end

    def replace_codon_at_pos(third_site, new_codon)
        replace_nt_at_pos(third_site-2, new_codon[0])
        replace_nt_at_pos(third_site-1, new_codon[1])
        replace_nt_at_pos(third_site, new_codon[2])
    end

    def replace_nt_at_pos(pos, new_nt)
        @exons.each do |exon|
            if pos >= exon.size
                pos -= exon.size
            else
                exon[pos] = new_nt
                break
            end
        end
    end

    def init_codon_replacement_log
        @number_of_changed_sites = 0
        @changed_sites = ""
    end

    def log_codon_replacement(log)
        @number_of_changed_sites += 1
        @changed_sites += "#{log}\n"
    end
end