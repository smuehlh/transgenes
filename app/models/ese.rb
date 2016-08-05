class Ese < ActiveRecord::Base

    def reset
        self.update_attributes(
            data: ""
        )
    end
end
