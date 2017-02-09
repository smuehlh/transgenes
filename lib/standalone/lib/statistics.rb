module Statistics

    def self.mean(arr)
        sum = sum(arr)
        len = arr.size
        sum/len.to_f
    end

    def self.sum(arr)
        arr.inject(:+)
    end

    def self.normalise_scores_or_set_equal_if_all_scores_are_zero(arr)
        sum = sum(arr)
        if sum == 0
            # all syn_codons are equally (un-)likely. avoid diving by 0
            equal_scores_size(arr.size)
        else
            arr.collect{|val| val/sum.to_f}
        end
    end

    private

    def self.equal_scores_size(n)
        Array.new(n) {1/n.to_f}
    end
end