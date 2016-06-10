class Submit
    include ActiveModel::Model

    attr_accessor :keep_first_intron, :avoid_CpG, :adjust_nt_usage_along_cds,
        :strategy
end