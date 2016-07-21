module CoreExtensions
    module FileParsing

        # future class method
        def get_all_feature_starts(use_feature, file)
            obj = ToGene.new(use_feature)
            obj.split_file_into_features_and_return_formatted_features(file)
        rescue EnhancerError
            # re-raise error. handle in web-interface
            raise
        rescue StandardError => exp
            # something went very wrong. most likely the input file is corrupt.
            ErrorHandling.abort_with_error_message(
                "invalid_file_format", @file_info
            )
        end

        # future instance method
        # features will be formatted for output in error messages
        def split_file_into_features_and_return_formatted_features(file)
            ensure_file_format_and_split_file_into_features(file)
            formatted_records_with_starts =
                @feature_records_by_feature_starts.collect do |start, record|
                    [start, truncate_record(record)]
                end.to_h
        end
    end
end