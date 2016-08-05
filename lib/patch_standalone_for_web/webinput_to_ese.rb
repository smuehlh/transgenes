class WebinputToEse

    attr_reader :error

    def initialize(ese_params, is_fileupload_input)
        @error = "" # NOTE: use @error instead of log-content to customize error messages.
        @ese_motifs = []
        CoreExtensions::Settings.setup

        file = get_fileupload_path_or_save_textinput_to_file(
            ese_params, is_fileupload_input)
        parse_file_and_get_ese_motifs(file)
        delete_textinput_file(file)
    end

    def get_ese_motifs
        @ese_motifs.any? ? @ese_motifs : []
    end

    private

    def get_fileupload_path_or_save_textinput_to_file(params, is_fileupload_input)
        if is_fileupload_input
            params[:file].path
        else
            write_textinput_to_file(params[:data])
        end
    end

    def write_textinput_to_file(data)
        file = Tempfile.new(['gene', '.txt'])
        file.write(data)
        file.close
        file
    end

    def delete_textinput_file(file)
        # remove tempfile (was created only in case of textinput)
        file.delete if file.kind_of?(Tempfile)
    end

    def parse_file_and_get_ese_motifs(file)
        @ese_motifs = EseToGene.init_and_parse(file)
    rescue EnhancerError => exception
        @error = exception.to_s
    end
end