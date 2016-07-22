class WebinputToOptions

    attr_reader :strategy, :remove_first_intron, :error

    def initialize(submit_params)
        CoreExtensions::Settings.setup("logger")

        @error = ""

        @remove_first_intron = ! submit_params[:keep_first_intron]
        @strategy =
            case submit_params[:strategy]
            when "humanize" then "humanize"
            when "gc" then "gc"
            when "raw" then "raw"
            else
                @error = "Unknown strategy #{submit_params[:strategy]}"
            end
    end
end