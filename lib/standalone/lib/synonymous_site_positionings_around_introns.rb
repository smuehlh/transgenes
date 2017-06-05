class SynonymousSitePositioningsAroundIntrons

    def initialize(exons, introns, syn_sites)
        @exons = exons
        @introns = introns
        @exon_coordinates_by_syn_sites = syn_sites.collect do |pos|
            [pos, convert_syn_site_position_into_exon_coordinates(pos)]
        end.to_h
    end

    def is_in_proximity_to_deleted_intron(syn_site)
        pos_in_exon, exon_ind = @exon_coordinates_by_syn_sites[syn_site]
        (
            is_at_exon_start(pos_in_exon, exon_ind) &&
            is_preceded_by_intron(exon_ind) &&
            is_preceding_intron_deleted(exon_ind)
        ) || (
            is_at_exon_end(pos_in_exon, exon_ind) &&
            is_succeeded_by_intron(exon_ind) &&
            is_succeeding_intron_deleted(exon_ind)
        )
    end

    def is_in_proximity_to_intron(syn_site)
        pos_in_exon, exon_ind = @exon_coordinates_by_syn_sites[syn_site]
        (
            is_succeeded_by_intron(exon_ind) &&
            (! is_succeeding_intron_deleted(exon_ind)) &&
            is_at_exon_end(pos_in_exon, exon_ind)
        ) || (
            is_preceded_by_intron(exon_ind) &&
            (! is_preceding_intron_deleted(exon_ind)) &&
            is_at_exon_start(pos_in_exon, exon_ind)
        )
    end

    def get_nt_distance_to_intron(syn_site)
        pos_in_exon, exon_ind = @exon_coordinates_by_syn_sites[syn_site]
        if pos_in_exon < @exons[exon_ind].size/2
            pos_in_exon
        else
            -(@exons[exon_ind].size - pos_in_exon)
        end
    end

    private

    def convert_syn_site_position_into_exon_coordinates(pos)
        @exons.each_with_index do |exon, ind|
            if pos >= exon.size
                pos -= exon.size
                next
            else
                return [pos, ind]
            end
        end
    end

    def is_at_exon_start(pos, exon_ind)
        pos < exon_border_width(exon_ind)
    end

    def is_at_exon_end(pos, exon_ind)
        pos >= @exons[exon_ind].size - exon_border_width(exon_ind)
    end

    def exon_border_width(exon_ind)
        if @exons[exon_ind].size < Constants.number_of_nucleotides_to_tweak * 2
            @exons[exon_ind].size/2
        else
            Constants.number_of_nucleotides_to_tweak
        end
    end

    def is_preceded_by_intron(exon_ind)
        exon_ind != 0
    end

    def is_succeeded_by_intron(exon_ind)
        exon_ind != @exons.size - 1
    end

    def is_preceding_intron_deleted(exon_ind)
        # NOTE: relies on the fact that there is an preceding intron
        @introns[exon_ind-1].nil?
    end

    def is_succeeding_intron_deleted(exon_ind)
        # NOTE: relies on the fact that there is an succeeding intron
        @introns[exon_ind].nil?
    end
end