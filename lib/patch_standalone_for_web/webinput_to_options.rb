class WebinputToOptions

    attr_reader :strategy, :ese_strategy, :select_by,
        :remove_first_intron, :stay_in_subbox_for_6folds,
        :score_eses_at_all_sites

    def initialize(submit_params)
        @remove_first_intron = ! submit_params[:keep_first_intron]
        @stay_in_subbox_for_6folds = submit_params[:stay_in_subbox]
        @strategy =
            case submit_params[:strategy]
            when "humanize" then "humanize"
            when "gc" then "gc"
            when "raw" then "raw"
            when "max_gc" then "max-gc"
            else
                # this should never happen. 'raw' seems to be a good fall-back, though.
                $logger.warn "Passed an invalid strategy. Use strategy 'raw' instead."
                "raw"
            end
        @select_by = submit_params[:select_by]
        @ese_strategy = submit_params[:ese_strategy]
        @score_eses_at_all_sites = submit_params[:score_eses_at_all_sites]
    end

    def is_keep_first_intron
        ! @remove_first_intron
    end

    def log_program_call(has_ese_motifs)
        params = "--strategy #{@strategy} --select-by #{@select_by}"
        params += " --ese-strategy #{@ese_strategy}" if has_ese_motifs
        params += " --stay-in-codon-box" if @stay_in_subbox_for_6folds
        params += " --remove-first-intron" if @remove_first_intron
        $logger.info "Commandline parameters: #{params}"
    end
end