class EnhanceTransgenesController < ApplicationController
    def new
        save_text_input_to_session(params["input-cds-text"], "cds") if params["input-cds-text"]
        save_text_input_to_session(params["input-five-text"], "utr-five") if params["input-five-text"]
        save_text_input_to_session(params["input-three-text"], "utr-three") if params["input-three-text"]
    end

    def save_text_input_to_session(input, key)
        init_input_data_session_store(key) unless session.key?(key)
        session[key]["is_file"] = false
        session[key]["data"] = input
    end

    def init_input_data_session_store(key)
        session[key] = {
            # creates stings, not symbols as keys
            is_file: false,
            data: ""
        }
    end
end
