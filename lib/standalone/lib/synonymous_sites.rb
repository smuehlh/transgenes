class SynonymousSites

    def self.all_sites(exons)
        # HOTFIX - need third codon positions as both class and instance method
        first_synonymous_site = 2
        last_synonymous_site = exons.join("").size - 1
        (first_synonymous_site..last_synonymous_site).step(3).to_a
    end

    def self.preceeding_codon_at(cds_tweaked_up_to_pos, pos)
        # NOTE - codon at pos-3 might have been changed,
        # thus, cannot use original_codon_at(pos-3)
        if pos-5 < 0
            # out of bounds case analogous to get_neighbouring_codon_at()
            nil
        else
            cds_tweaked_up_to_pos[pos-5..pos-3]
        end
    end

    def initialize(exons, introns, stay_in_subbox_for_6folds)
        @syn_sites = get_third_codon_positions(exons)
        @orig_codons_by_site = collect_original_codons(exons)
        @syn_codons_by_site = collect_synonymous_codons(stay_in_subbox_for_6folds)

        mapping_obj = prepare_syn_site_mapping_to_exon_positions(exons, introns)
        @near_deleted_intron_flags_by_site = collect_nearness_to_deleted_introns(mapping_obj)
        @near_existing_intron_flags_by_site = collect_nearness_to_existing_introns(mapping_obj)
        @distances_to_introns_by_site = collect_distances_to_introns(mapping_obj)

        @windows_covering_site = collect_window_positions(exons)
    end

    def all_sites
        @syn_sites
    end

    def original_codon_at(pos)
        @orig_codons_by_site[pos]
    end

    def synonymous_codons_at(pos)
        @syn_codons_by_site[pos]
    end

    def neighbouring_codon_at(pos)
        # returns nil if pos+3 is out of bounds (i.e. pos was last codon pos)
        original_codon_at(pos+3)
    end

    def neighbouring_synonymous_codons_at(pos)
        synonymous_codons_at(pos+3)
    end

    def is_stopcodon_at(pos)
        GeneticCode.is_stopcodon(original_codon_at(pos))
    end

    def is_in_proximity_to_deleted_intron(pos)
        @near_deleted_intron_flags_by_site[pos]
    end

    def is_in_proximity_to_intron(pos)
        @near_existing_intron_flags_by_site[pos]
    end

    def get_nt_distance_to_intron(pos)
        @distances_to_introns_by_site[pos]
    end

    def reduce_synonymous_codons_to_same_subbox_at(pos)
        # NOTE - use this method only in exceptional cases only as it will overwrite stay_in_subbox_for_6folds settings for a single position
        codon = original_codon_at(pos)
        if GeneticCode.is_6fold_degenerate(codon)
            @syn_codons_by_site[pos] =
                GeneticCode.get_synonymous_codons_in_codon_box(codon)
        # else - nothing to do; this affects 6folds only
        end
    end

    def sequence_windows_covering_syn_codons_at(cds, pos)
        # NOTE - use up-to-date cds as it might contain tweaks just before pos
        start, stop = @windows_covering_site[pos]
        window_head =
            if pos-3 < 0
                "" # synonyous site is at beginning of window
            else
                cds[start..pos-3] # pos-3: last pos before syn codon
            end
        window_tail = cds[pos+1..stop]

        @syn_codons_by_site[pos].collect do |codon|
            maxwindow = window_head + codon + window_tail
            maxwindow.chars.each_cons(Constants.window_size).collect{|arr| arr.join}
        end
    end

    private

    def get_third_codon_positions(exons)
        # HOTFIX - need third codon positions as both class and instance method
        SynonymousSites.all_sites(exons)
    end

    def collect_original_codons(exons)
        cds = exons.join("")
        @syn_sites.collect do |pos|
            [pos, cds[pos-2..pos]]
        end.to_h
    end

    def collect_synonymous_codons(stay_in_subbox_for_6folds)
        @orig_codons_by_site.collect do |pos, codon|
            syn_codons =
                if stay_in_subbox_for_6folds
                    GeneticCode.get_synonymous_codons_in_codon_box(codon)
                else
                    GeneticCode.get_synonymous_codons(codon)
                end
            [pos, syn_codons]
        end.to_h
    end

    def prepare_syn_site_mapping_to_exon_positions(exons, introns)
        SynonymousSitePositioningsAroundIntrons.new(exons, introns, @syn_sites)
    end

    def collect_nearness_to_deleted_introns(mapping_obj)
        @syn_sites.collect do |pos|
            [pos, mapping_obj.is_in_proximity_to_deleted_intron(pos)]
        end.to_h
    end

    def collect_nearness_to_existing_introns(mapping_obj)
        @syn_sites.collect do |pos|
            [pos, mapping_obj.is_in_proximity_to_intron(pos)]
        end.to_h
    end

    def collect_distances_to_introns(mapping_obj)
        @syn_sites.collect do |pos|
            [pos, mapping_obj.get_nt_distance_to_intron(pos)]
        end.to_h
    end

    def collect_window_positions(exons)
        # can't collect actual sequence windows, as sequence will change while tweaking the gene
        obj = SynonymousSiteContainingSequenceWindows.new(exons)
        @syn_codons_by_site.collect do |pos, codons|
            [pos, obj.get_coordinates_of_window_covering_syn_site(pos, codons)]
        end.to_h
    end
end