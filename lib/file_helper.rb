module FileHelper

    extend self

    def file_exist?(path)
        FileTest.file?(path)
    end
    def file_exist_or_die(path)
        abort "Failed to open: #{path}" if ! file_exist?(path)
    end
    def split_filename_and_extension(path)
        basename = File.basename(path)
        extension = File.extname(basename)
        [ File.basename(basename, extension), extension ]
    end
end