module FileHelper

    extend self

    def file_exist?(path)
        FileTest.file?(path)
    end

    def file_exist_or_die(path)
        abort "Failed to open: #{path}" unless file_exist?(path)
    end

    def get_file_extension(path)
        split_filename_and_extension(path).last.downcase
    end

    def split_filename_and_extension(path)
        basename = File.basename(path)
        extension = File.extname(basename)
        [ File.basename(basename, extension), extension ]
    end

    def write_to_file(path, data)
        fh = File.open(path, "w")
        fh.puts data
        fh.close
    end
end