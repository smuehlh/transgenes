class Gene
    attr_reader :exons, :introns, :five_prime_utr, :three_prime_utr, :description,
        :gc3_content, :gc3_count_per_synonymous_site, :sequence_proportion_covered_by_eses

    def initialize
        @description = ""
        @exons = [] # CDS only, excluding UTR's
        @introns = []
        @five_prime_utr = "" # exons and introns merged
        @three_prime_utr = "" # exons and introns merged

        @gc3_content = ""
        @gc3_count_per_synonymous_site = []
        @sequence_proportion_covered_by_eses = ""

        @ese_motifs = {} # save motifs as hash keys for faster lookup
    end

    def ese_motifs
        # NOTE - use custom getter to convert motifs hash to array
        # (which is the more obvious, but slower way of storing eses)
        @ese_motifs.keys
    end

    def add_cds(exons, introns, gene_name)
        @exons = exons
        @introns = introns
        @description = gene_name

        @gc3_content = get_gc3_content
        @gc3_count_per_synonymous_site = get_gc3_counts_per_site
    end

    def add_five_prime_utr(exons, introns, dummy)
        @five_prime_utr = combine_exons_and_introns(exons, introns)
    end

    def add_three_prime_utr(exons, introns, dummy)
        @three_prime_utr = combine_exons_and_introns(exons, introns)
    end

    def add_ese_list(ese_motifs)
        ese_motifs.each {|motif| @ese_motifs[motif] = nil}
        @sequence_proportion_covered_by_eses = get_sequence_proporion_covered_by_eses if @exons.any?
    end

    def remove_introns(is_remove_first_intron)
        @introns = is_remove_first_intron ? [] : [@introns.first]
    end

    def log_statistics
        str = "Gene name: #{@description}\n"
        str += "Number of exons: #{@exons.size}\n"
        first_intron_kept = @introns.size == 1
        str += "All introns " + (first_intron_kept ? "but" : "including") + " the first removed.\n"
        n_aa = @exons.join("").size / 3
        str += "Number of amino acids: #{n_aa}\n"
        utr_flag =
            if @five_prime_utr.empty? && @three_prime_utr.empty?
                ""
            elsif ! @five_prime_utr.empty? && @three_prime_utr.empty?
                " (including 5'UTR)"
            elsif @five_prime_utr.empty? && ! @three_prime_utr.empty?
                " (including 3'UTR)"
            else
                " (including 5'UTR and 3'UTR)"
            end
        str += "Total mRNA size#{utr_flag}: #{sequence.size}"
        $logger.info(str)
    end

    def sequence
        # NOTE - can't precalc as data is added gradually
        @five_prime_utr + combine_exons_and_introns(@exons, @introns) + @three_prime_utr
    end

    def prepare_for_tweaking(stay_in_subbox_for_6folds)
        # NOTE - keep this method seperate from tweak_sequence():
        # preparation needs to be done only once
        @synonymous_sites = SynonymousSites.new(@exons, @introns, stay_in_subbox_for_6folds)
    end

    def tweak_exonic_sequence(strategy)
        scorer = ScoreSynonymousCodons.new(strategy, @synonymous_sites, @ese_motifs)
        init_codon_replacement_log
        init_exon_copy

        @synonymous_sites.all_sites.each do |pos|
            # NOTE - pass up-to-date tweaked exons to scorer:
            # ESE-scores considers the already tweaked sequence upstream of pos
            codon = scorer.select_synonymous_codon_at(@tweaked_exons.join, pos)

            if ! scorer.is_original_codon_selected_at(pos, codon)
                replace_codon_at_pos(@tweaked_exons, pos, codon)
                log_codon_replacement(scorer.log_selected_codon_at(pos, codon))
            end
        end
    end

    def log_changed_sites
        [@number_of_changed_sites, @changed_sites]
    end

    def deep_copy_using_tweaked_sequence(copy_number)
        updated_description = "Variant #{copy_number}: #{Statistics.percents(@gc3_content)}% GC, #{@number_of_changed_sites} changed sites"
        if @ese_motifs.any?
            updated_description += ", #{Statistics.percents(@sequence_proportion_covered_by_eses)}% of sequence covered by ESEs"
        end
        updated_description += ". [Variant of: #{@description}]"

        copy = self.dup
        copy.add_cds(@tweaked_exons, @introns, updated_description)
        copy.add_ese_list(@ese_motifs.keys) # recalc seq-proportion covered by eses

        copy
    end

    private

    def combine_exons_and_introns(exons, introns)
        exons.zip(introns).flatten.compact.join("")
    end

    def get_gc3_content
        gc3_counts = get_gc3_counts_per_site
        Statistics.sum(gc3_counts)/gc3_counts.size.to_f
    end

    def get_gc3_counts_per_site
        cds = @exons.join("")
        SynonymousSites.all_sites(@exons).collect{|pos| cds[pos].count("GC")}
    end

    def get_sequence_proporion_covered_by_eses
        cds = @exons.join("")
        pos_covering_eses = (0..cds.size-1).collect do |start|
            # NOTE - last couple of windows will be too short
            # this is ok, as they won't be part of ese-motifs anyway.
            stop = start + Constants.window_size - 1
            window = cds[start..stop]
            if @ese_motifs.has_key?(window)
                (start..stop).to_a
            end
        end.flatten.compact.uniq

        pos_covering_eses.size/cds.size.to_f
    end

    def replace_codon_at_pos(exons, third_site, new_codon)
        replace_nt_at_pos(exons, third_site-2, new_codon[0])
        replace_nt_at_pos(exons, third_site-1, new_codon[1])
        replace_nt_at_pos(exons, third_site, new_codon[2])
    end

    def replace_nt_at_pos(exons, pos, new_nt)
        exons.each do |exon|
            if pos >= exon.size
                pos -= exon.size
            else
                exon[pos] = new_nt
                break
            end
        end
    end

    def init_exon_copy
        @tweaked_exons = []
        @exons.each{|exon| @tweaked_exons.push exon.dup }

        @tweaked_exons
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