module Constants
    extend self

    def number_of_nucleotides_to_tweak
        70
    end

    def window_size
        @window_size || 6
    end

    def window_size=(var)
        @window_size = var
    end

    def min_motif_length
        5
    end

    def max_motif_length
        10
    end
end