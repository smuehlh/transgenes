module FileHelper

    extend self

    def file_exist?(path)
        FileTest.file?(path)
    end
    def file_exist_or_die(path)
        abort "Failed to open: #{path}" if ! file_exist?(path)
    end

end