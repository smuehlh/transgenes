module EnhanceTransgenesHelper

    def get_input_data_from_session(key)
        session[key]["data"] if session[key] && session[key]["data"]
    end

end
