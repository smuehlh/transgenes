class String

    def is_upper?
        ! self.match /[[:lower:]]/
    end

    def is_lower?
        ! self.match /[[:upper:]]/
    end
    
    def regexp_delete(regexp)
        gsub(regexp, '')
    end

end