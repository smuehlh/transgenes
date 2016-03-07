class String

    def is_upper?
        ! self.match /[[:lower:]]/
    end

    def is_lower?
        ! self.match /[[:upper:]]/
    end
    
end