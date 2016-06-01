class WebinputToGene


# TODO convert_input_to_gene ersetzen
#  an to-gene.rb anlehnen

end

    # def parse_file_for_web_or_die(file)
    #     ensure_file_format_and_split_file_into_features(file)
    # rescue EnhancerError
    #     # re-raise error. handle in web-interface
    #     raise
    # rescue StandardError => exp
    #     # something went very wrong. most likely the input file is corrupt.
    #     ErrorHandling.abort_with_error_message(
    #         "invalid_file_format", @file_info
    #     )
    # end

    # def parse_feature_for_web_or_die(use_feature_starting_in_line)
    #     parse_feature_and_ensure_feature_format(use_feature_starting_in_line)
    # rescue EnhancerError
    #     # re-raise error. handle in web-interface
    #     raise
    # rescue StandardError => exp
    #     # something went very wrong. most likely the input file is corrupt.
    #     ErrorHandling.abort_with_error_message(
    #         "invalid_file_format", @file_info
    #     )
    # end

    # def get_features_with_starting_lines_for_web
    #     @feature_records_by_feature_starts || {}
    # end