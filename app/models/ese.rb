class Ese < ActiveRecord::Base

    serialize :data

    def reset
        self.update_attribute(:data, [])
    end
end
