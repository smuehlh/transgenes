class SynonymousSiteContainingSequenceWindows

    def initialize(exons)
        @cds = exons.join()
    end

    def get_coordinates_of_window_covering_syn_site(syn_site, syn_codons)
        is_sixfold = is_site_treated_as_sixfold?(syn_codons)
        window_starts = get_startpositions_of_windows_containing_pos(syn_site, is_sixfold)
        start = window_starts.first
        stop = window_starts.last + ind_last_pos_in_window

        [start, stop]
    end

    private

    def is_site_treated_as_sixfold?(syn_codons)
        syn_codons.size == 6
    end

    def get_startpositions_of_windows_containing_pos(pos, is_site_sixfold)
        # need first two snippets only if the codon is a 6-fold and all 6 are indeed considered for syn. substitution
        codonstart = is_site_sixfold ? pos - 2 : pos
        codonstop = pos
        snippet_starts = ((codonstart-ind_last_pos_in_window)..codonstop)
        snippet_starts.reject do |startpos|
            stoppos = startpos + ind_last_pos_in_window
            startpos < 0 || stoppos >= @cds.size
        end
    end

    def ind_last_pos_in_window
        Constants.window_size - 1
    end
end