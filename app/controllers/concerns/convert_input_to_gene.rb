module ConvertInputToGene
    extend ActiveSupport::Concern

    class ParseGene
        attr_reader :error

        def initialize(params)
            @error = nil

            write_text_input_to_file(params) if is_text_input(params)
            parse_input_file_to_records(params[:file], params[:name])
            delete_text_input_file(params) if is_text_input(params)

            parse_first_record
        end

        def get_sequence
            @error.nil? ? @to_gene_obj.get_sequence : ""
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

        def parse_first_record
            @to_gene_obj.parse_feature_for_web_or_die(get_starting_line_first_record
            )
        rescue EnhancerError => exception
            @error = exception.to_s
        end

        def get_starting_line_first_record
            @to_gene_obj.get_features_with_starting_lines_for_web.keys.first
        end
    end

end