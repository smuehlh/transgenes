module ErrorHandling

    extend self

    def is_commandline_tool
        @is_commandline_tool
    end

    def is_commandline_tool=(bool)
        @is_commandline_tool = bool
    end

    def error_message_with_reference_to_commandline_option_help(str = "")
        help_ref = "Add --help to program call to view all options and their arguments."
        str == "" ? help_ref : "#{str}\n#{help_ref}"
    end

    def error_message_with_reference_to_input_file(file)
        "Unrecognized file format: #{file}.\nInput has to be either a GeneBank record or a FASTA file."
    end

    def error_message_with_reference_to_valid_gene_starts(type, str)
        "#{type} gene start specified.\nSpecify one of the following genes using argument --line <starting-line>:\n#{str}"
    end

    def error_message_nothing_to_do(file)
        "Nothing to do: #{file}.\nMust leave all exons unchanged."
    end

    def warning_message(str)
        "Warning: #{str}"
    end

    def error_code_to_commandline_error_message(code, additional_error_message = "")
        case code
        when "argument_error"
            error_message_with_reference_to_commandline_option_help(additional_error_message
            )
        when "missing_mandatory_argument"
            error_message_with_reference_to_commandline_option_help(
                "Missing mandatory option: #{additional_error_message}."
            )
        when "invalid_file_format"
            error_message_with_reference_to_input_file(
                additional_error_message
            )
        when "invalid_gene_start"
            error_message_with_reference_to_valid_gene_starts(
                "Invalid", additional_error_message
            )
        when "missing_gene_start"
            error_message_with_reference_to_valid_gene_starts(
                "No", additional_error_message
            )
        when "no_exon_to_tweak"
            error_message_nothing_to_do(additional_error_message)
        end
    end

    def error_code_to_commandline_warning_message(code, additional_warning_message = "")
        case code
        when "partial_gene"
            warning_message("Gene is partial.")
        end
    end

    def abort_with_error_message(code, additional_error_message = "")
        if is_commandline_tool
            abort error_code_to_commandline_error_message(
                code, additional_error_message
            )
        else
            # TODO
            # webserver
        end
    end

    def warn_with_error_message(code, additional_warning_message = "")
        if is_commandline_tool
            warn error_code_to_commandline_warning_message(
                code, additional_warning_message
            )
        else
            # TODO
            # webserver
        end
    end
end