class SynonymousSites

    def initialize(exons, introns)
        @exons = exons
        @introns = introns
    end

    def get_synonymous_sites_in_exons
        @exons.each_with_index.collect do |exon, exon_ind|
            get_synonymous_sites_at_beginning_of_exon(exon_ind) if is_not_first_exon(exon_ind) &&
                is_preceeding_intron_deleted(exon_ind)

            get_synonymous_sites_at_end_of_exon(exon_ind) if
                is_not_last_exon(exon_ind) &&
                is_succeeding_intron_deleted(exon_ind)

        # use 'compact' to ensure an empty array is return in case no positions are found.
        end.flatten.compact
    end

    def get_synonymous_sites_in_cds
        # = all third codon positions
        first_synonymous_site = 2
        last_potential_site = @exons.join("").size - 1
        (first_synonymous_site..last_potential_site).step(3)
    end

    def is_in_proximity_to_deleted_intron(pos_in_cds)
        pos_in_exon, exon_ind = map_cds_pos_onto_exon_pos_and_ind(pos_in_cds)
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

    private

    def map_cds_pos_onto_exon_pos_and_ind(pos)
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




    def is_not_first_exon(exon_index)
        exon_index != 0
    end

    def is_not_last_exon(exon_index)
        exon_index != @exons.size - 1
    end

    def is_preceeding_intron_deleted(exon_index)
        # NOTE: this method fails for the first exon
        @introns[exon_index-1] ? false : true
    end

    def is_succeeding_intron_deleted(exon_index)
        # NOTE: this method fails for the last exon
        @introns[exon_index] ? false : true
    end

    def get_synonymous_sites_at_beginning_of_exon(exon_index)
        synonymous_sites_in_exon = get_all_synonymous_sites_in_exon(exon_index)
        last_position_within_margin =
            cds_length_upto_exon(exon_index) +
            number_of_nucleotides_to_tweak_in_exon(exon_index)

        synonymous_sites_in_exon.select{ |e| e < last_position_within_margin }
    end

    def get_synonymous_sites_at_end_of_exon(exon_index)
        synonymous_sites_in_exon = get_all_synonymous_sites_in_exon(exon_index)
        first_position_within_margin =
            cds_length_including_exon(exon_index) -
            number_of_nucleotides_to_tweak_in_exon(exon_index)

        synonymous_sites_in_exon.select{ |e| e > first_position_within_margin }
    end

    def get_all_synonymous_sites_in_exon(exon_index)
        exon_startpos_in_cds = cds_length_upto_exon(exon_index)
        exon_length = @exons[exon_index].size
        first_synonymous_site =
            # synonymous sites: 3. codon positions in this exon.
            case exon_startpos_in_cds % 3
            when 0 then exon_startpos_in_cds + 2
            when 1 then exon_startpos_in_cds + 1
            when 2 then exon_startpos_in_cds
            end
        # -1 to access array as [0..last_potential_site]
        last_potential_site = exon_startpos_in_cds + exon_length - 1
        (first_synonymous_site..last_potential_site).step(3)
    end

    def cds_length_upto_exon(exon_index)
        exon_index == 0 ? 0 : @exons[0..exon_index-1].join("").size
    end

    def cds_length_including_exon(exon_index)
        @exons[0..exon_index].join("").size
    end

    def number_of_nucleotides_to_tweak_in_exon(exon_index)
        exon_length = @exons[exon_index].size
        exon_length < 140 ? exon_length / 2 : Constants.number_of_nucleotides_to_tweak
    end
end