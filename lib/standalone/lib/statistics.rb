module Statistics

    def self.mean(arr)
        sum = arr.inject(:+)
        len = arr.size
        sum/len.to_f
    end
end