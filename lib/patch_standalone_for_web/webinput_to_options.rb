class WebinputToOptions

    attr_reader :strategy, :remove_first_intron

    def initialize(submit_params)
        CoreExtensions::Settings.setup("logger")
        @remove_first_intron = ! submit_params[:keep_first_intron]

        @strategy =
            case submit_params[:strategy]
            when "humanize" then "humanize"
            when "gc" then "gc"
            when "raw" then "raw"
            else
                # this should never happen. 'raw' seems to be a good fall-back, though.
                $logger.warn "Passed an invalid strategy. Will use strategy 'raw' instead."
                "raw"
            end
    end
end