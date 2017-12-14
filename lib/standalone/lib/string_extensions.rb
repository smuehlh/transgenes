class String

    def is_upper?
        self.match(/[[:upper:]]/)
    end

    def is_lower?
        self.match(/[[:lower:]]/)
    end

    def regexp_delete(regexp)
        gsub(regexp, '')
    end

    def all_indices(substring)
        i = -1
        all = []
        while i = self.index(substring, i+1)
            all << i
        end
        all
    end
end