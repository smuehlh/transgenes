module EnhancersHelper
    def word_wrap_breaking_single_word(word, maxlength)
        if word.size > maxlength
            word.scan(/.{1,#{maxlength}}/).join("\n")
        else
            word
        end
    end

    def teaser_wrapped_single_word_with_ellipsis(wrapped_word)
        teaser = wrapped_word.split("\n").first
        wrapped_word.include?("\n") ? "#{teaser}..." : teaser
    end

    def patch_multiline_text_for_web(text)
        text.gsub("\n", "<br>").html_safe
    end

    def html_compatible_enhancer_name(name)
        case name
        when "5'UTR" then "five"
        when "CDS" then "cds"
        when "3'UTR" then "three"
        end
    end
end
