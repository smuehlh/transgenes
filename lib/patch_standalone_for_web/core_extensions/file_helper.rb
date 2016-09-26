module CoreExtensions
    module FileHelper

        def write_to_temp_file(basename, extension, data)
            file = Tempfile.new([basename, extension])
            file.write(data)
            file.flush
            file
        end

        def delete_temp_file(file)
            # remove tempfile (only if it is an tempfile)
            file.close! if file.kind_of?(Tempfile)
        end
    end
end