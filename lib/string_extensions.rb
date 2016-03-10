class String

    def is_upper?
        self.match /[[:upper:]]/
    end

    def is_lower?
        self.match /[[:lower:]]/
    end

    def regexp_delete(regexp)
        gsub(regexp, '')
    end

end