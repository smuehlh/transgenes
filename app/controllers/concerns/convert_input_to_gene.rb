module ConvertInputToGene
    extend ActiveSupport::Concern

    class ParseGene
        attr_reader :error

        def initialize(params)
            @error = nil
            @sequences_with_keys = {}

            write_text_input_to_file(params) if is_text_input(params)
            parse_input_file_to_records(params[:file], params[:name])
            delete_text_input_file(params) if is_text_input(params)

            @sequences_with_keys = parse_gene_records
        end

        def get_sequences
            @error.nil? ? @sequences_with_keys : {}
        end

        private

        def is_text_input(params)
            params[:data]
        end

        def write_text_input_to_file(params)
            ext = get_file_extension_matching_input_type(params[:data])
            file = Tempfile.new(['gene', ext])
            file.write(params[:data])
            file.close
            params[:file] = file
        end

        def delete_text_input_file(params)
            # remove tempfile (was created only in case of textinput)
            params[:file].delete if params[:file].respond_to?(:delete)
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

        def parse_input_file_to_records(file, feature_type)
            @to_gene_obj = ToGene.new(feature_type)
            @to_gene_obj.parse_file_for_web_or_die(file)
        rescue EnhancerError => exception
            @error = exception.to_s
        end

        def parse_gene_records
            starting_lines_with_gene_records = {}
            all_starting_lines.each do |line|
                parse_gene_record_starting_in(line)
                starting_lines_with_gene_records[line] = get_sequence
            end
            starting_lines_with_gene_records
        end

        def parse_gene_record_starting_in(line)
            @to_gene_obj.parse_feature_for_web_or_die(line)
        rescue EnhancerError => exception
            @error = exception.to_s
        end

        def all_starting_lines
            @to_gene_obj.get_features_with_starting_lines_for_web.keys
        end

        def get_sequence
            @error.nil? ? @to_gene_obj.get_sequence : ""
        end
    end

end