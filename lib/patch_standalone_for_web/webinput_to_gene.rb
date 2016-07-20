class WebinputToGene
    ToGene.extend CoreExtensions::FileParsing
    ToGene.include CoreExtensions::FileParsing

    attr_reader :error, :warning

    def initialize(enhancer_params, is_fileupload_input)
        @error = nil
        @warning = nil
        @starting_lines_with_gene_records = {}
        CoreExtensions::Settings.setup("logger")

        feature_type = enhancer_params[:name]
        file = get_fileupload_path_or_save_textinput_to_file(
            enhancer_params, is_fileupload_input)

        parse_file_and_get_gene_records(feature_type, file)
        delete_textinput_file(file)

        CoreExtensions::Settings.close_logger
    end

    def get_records
        @gene_records.any? ? @gene_records : {}
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

    def parse_file_and_get_gene_records(feature_type, file)
        @gene_records = {}
        starting_lines = get_first_feature_starts_and_warn_if_max_num_is_exceeded(
                feature_type, file
            )
        starting_lines.each do |line|
            gene = Gene.new
            begin
                gene.add_cds(*ToGene.init_and_parse(feature_type, file, line))
            rescue EnhancerError => exception
                str = "Gene record in line #{line}: #{exception.to_s}"
                @error = @error ? "#{@error}\n#{str}" : str
                next
            end
            @gene_records[line] = {
                exons: gene.exons,
                introns: gene.introns,
                sequence: gene.sequence,
                description: gene.description
            }
        end

    rescue EnhancerError => exception
        @error = exception.to_s
    end

    def get_first_feature_starts_and_warn_if_max_num_is_exceeded(feature_type, file)
        max_num = 10
        starts = ToGene.get_all_feature_starts(feature_type, file)
        if starts.size > max_num
            @warning = "Found too many gene records. Only the first #{max_num} have been parsed."
        end
        starts[0..max_num-1]
    end
end