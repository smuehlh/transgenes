class WebinputToRestrictionEnzyme

    include CoreExtensions::FileHelper

    attr_reader :error, :log

    def initialize(enzyme_params, is_fileupload_input)
        @error = "" # NOTE: use @error instead of log-content to customize error messages.
        @log = "" # NOTE: use @log to debug file-parsing
        @motifs = []
        CoreExtensions::Settings.setup_for_debugging

        file = get_fileupload_path_or_save_textinput_to_file(
            enzyme_params, is_fileupload_input)
        parse_file_and_get_motifs(file)
        delete_temp_file(file)
    ensure
        @log = CoreExtensions::Settings.get_log_content
    end

    def get_motifs
        @motifs.any? ? @motifs : []
    end

    def was_success?
        @error.blank?
    end

    private

    def get_fileupload_path_or_save_textinput_to_file(params, is_fileupload_input)
        if is_fileupload_input
            params[:file].path
        else
            base = "motif"
            ext = ".txt"
            data = params[:to_keep] || params[:to_avoid]
            write_to_temp_file(base, ext, data)
        end
    end

    def parse_file_and_get_motifs(file)
        @motifs = RestrictionEnzymeToGene.init_and_parse(file)
    rescue EnhancerError => exception
        @error = exception.to_s
    end
end