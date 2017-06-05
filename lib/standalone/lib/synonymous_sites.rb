class SynonymousSites

    def self.all_sites(exons)
        # HOTFIX - need third codon positions as both class and instance method
        first_synonymous_site = 2
        last_synonymous_site = exons.join("").size - 1
        (first_synonymous_site..last_synonymous_site).step(3).to_a
    end

    def initialize(exons, introns, stay_in_subbox_for_6folds)
        @syn_sites = get_third_codon_positions(exons)
        @orig_codons_by_site = collect_original_codons(exons)
        @syn_codons_by_site = collect_synonymous_codons(stay_in_subbox_for_6folds)

        mapping_obj = prepare_syn_site_mapping_to_exon_positions(exons, introns)
        @near_deleted_intron_flags_by_site = collect_nearness_to_deleted_introns(mapping_obj)
        @near_existing_intron_flags_by_site = collect_nearness_to_existing_introns(mapping_obj)
        @distances_to_introns_by_site = collect_distances_to_introns(mapping_obj)

        windows_obj = prepare_syn_site_mapping_to_sequence_windows(exons)
        @sequence_windows_covering_site = collect_sequence_windows(windows_obj)
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

    def sequence_windows_covering_syn_codon_at(pos)
        # by synonymous codon
        @sequence_windows_covering_site[pos]
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

    def prepare_syn_site_mapping_to_sequence_windows(exons)
        SynonymousSiteContainingSequenceWindows.new(exons, @syn_sites)
    end

    def collect_sequence_windows(windows_obj)
        @syn_codons_by_site.collect do |pos, codons|
            [pos, windows_obj.get_windows_covering_syn_codon_at_pos(pos, codons)]
        end.to_h
    end
end