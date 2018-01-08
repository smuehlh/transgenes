class RestrictionEnzyme < ActiveRecord::Base

    serialize :data

    def reset
        # NOTE - don't update attribute "name"
        self.update_attribute(:data, nil)
    end
end
