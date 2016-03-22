module ErrorHandling

    extend self

    def is_commandline_tool
        @is_commandline_tool
    end

    def is_commandline_tool=(bool)
        @is_commandline_tool = bool
    end

    def error_message_with_reference_to_commandline_option_help(str="")
        help_ref = "Add --help to program call to view all options and their arguments."
        str == "" ? help_ref : "#{str}\n#{help_ref}"
    end

    def error_code_to_commandline_error_message(code, additional_error_message="")
        case code
        when "argument_error"
            error_message_with_reference_to_commandline_option_help(additional_error_message
            )
        when "missing_mandatory_argument"
            error_message_with_reference_to_commandline_option_help(
                "Missing mandatory option: #{additional_error_message}."
            )
        end
    end


    def abort_with_error_message(code, additional_error_message="")
        if is_commandline_tool
            abort error_code_to_commandline_error_message(
                code, additional_error_message
            )
        else
            # TODO
        end
    end
end