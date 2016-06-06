class WebinputToGene
    ToGene.include CoreExtensions::FileParsing

    attr_reader :error

    def initialize(enhancer_params, is_fileupload_input)
        @error = nil
    end

    def get_records
        {}
    end
end