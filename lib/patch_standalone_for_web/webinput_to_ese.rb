class WebinputToEse

    include CoreExtensions::FileHelper

    attr_reader :error, :log

    def initialize(ese_params, is_fileupload_input)
        @error = "" # NOTE: use @error instead of log-content to customize error messages.
        @log = "" # NOTE: use @log to debug file-parsing
        @ese_motifs = []
        CoreExtensions::Settings.setup_for_debugging

        file = get_fileupload_path_or_save_textinput_to_file(
            ese_params, is_fileupload_input)
        parse_file_and_get_ese_motifs(file)
        delete_temp_file(file)
    ensure
        @log = CoreExtensions::Settings.get_log_content
    end

    def get_ese_motifs
        @ese_motifs.any? ? @ese_motifs : []
    end

    private

    def get_fileupload_path_or_save_textinput_to_file(params, is_fileupload_input)
        if is_fileupload_input
            params[:file].path
        else
            base = "gene"
            ext = ".txt"
            write_to_temp_file(base, ext, params[:data])
        end
    end

    def parse_file_and_get_ese_motifs(file)
        @ese_motifs = EseToGene.init_and_parse(file)
    rescue EnhancerError => exception
        @error = exception.to_s
    end
end