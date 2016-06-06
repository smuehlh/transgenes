module CoreExtensions
    module FileParsing

        # future class method
        def get_all_feature_starts(use_feature, file)
            obj = ToGene.new(use_feature)
            obj.split_file_into_features_and_return_feature_starts(file)
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
        def split_file_into_features_and_return_feature_starts(file)
            ensure_file_format_and_split_file_into_features(file)
            @feature_records_by_feature_starts.keys
        end
    end
end