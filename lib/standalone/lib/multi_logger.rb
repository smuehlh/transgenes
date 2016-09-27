class MultiLogger

    def initialize(*targets)
        @targets = targets
    end

    def change_infolog_to_debug
        @targets.each do |t|
            t.level = Logger::DEBUG if t.info?
        end
    end

    %w(log debug info warn error fatal unknown).each do |m|
        define_method(m) do |*args, &block|
            @targets.map { |t| t.send(m, *args, &block) }
        end
    end
end