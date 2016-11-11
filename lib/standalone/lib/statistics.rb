module Statistics

    def self.mean(arr)
        sum = sum(arr)
        len = arr.size
        sum/len.to_f
    end

    def self.sum(arr)
        arr.inject(:+)
    end

    def self.normalise(arr, sum=sum(arr))
        arr.collect{|val| val/sum.to_f}
    end
end