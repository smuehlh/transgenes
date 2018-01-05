class RestrictionEnzyme < ActiveRecord::Base

    serialize :to_avoid
    serialize :to_keep

    def reset
        self.update_attributes(
            to_keep: nil,
            to_avoid: nil
        )
    end
end
