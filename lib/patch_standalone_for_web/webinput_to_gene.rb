class WebinputToGene
    ToGene.include CoreExtensions::FileParsing

    attr_reader :error

    def initialize(enhancer_params, is_fileupload_input)
        @error = nil

        feature_type = enhancer_params[:name]
        file = get_fileupload_path_or_save_textinput_to_file(
            enhancer_params, is_fileupload_input)

        delete_textinput_file(file)
    end

    def get_records
        # dummy entry!
        {
            1 => {sequence: "ATG", exons: ["ATG", "TAG"], introns: ["yy"]}
        }
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
        ext = get_file_extension_matching_input_type(data)
        file = Tempfile.new(['gene', ext])
        file.write(data)
        file.close
        file
    end

    def get_file_extension_matching_input_type(data)
        if data.start_with?(">")
            # (might be) fasta input.
            ".fas"
        elsif data.start_with?("LOCUS")
            # (might be) genebank input.
            ".gb"
        else
            # unknown input.
            ".unknown"
        end
    end

    def delete_textinput_file(file)
        # remove tempfile (was created only in case of textinput)
        file.delete if file.kind_of?(Tempfile)
    end
end