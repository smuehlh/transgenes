class WebinputToOptions

    attr_reader :strategy, :select_by, :remove_first_intron, :stay_in_subbox_for_6folds

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
    end

    def is_keep_first_intron
        ! @remove_first_intron
    end
end