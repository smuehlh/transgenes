module Counting

    extend self

    def human_to_ruby(int) 
        int.to_i - 1
    end

    def ruby_to_human(int)
        int + 1
    end
end