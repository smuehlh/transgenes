class ZipStandalone

    attr_reader :zip_data

    def self.zip
        obj = ZipStandalone.new
        obj.zip_data
    end

    def self.get_main_filename_in_zip
        "main.rb"
    end

    def self.get_archive_name
        "sequenceOptimizer"
    end

    def initialize
        # use wildcard '*' to not include hidden files in current dir
        # exclude log-files, hidden files in any dir and the original main file
        # ensure (using sed) that the main file does not contain debugger-gem
        # remove that temporary main file
        @zip_data = `cd #{path_to_lib} && sed -e '/byebug/ {N; d;}' #{filename_main} > #{tmp_filename_main} && zip -r - * -x \*.log "*/\.*" #{filename_main} && rm #{tmp_filename_main}`
    end

    private

    def path_to_lib
        Rails.root.join("lib", "standalone")
    end

    def filename_main
        "sequence_optimizer.rb"
    end

    def tmp_filename_main
        self.class.get_main_filename_in_zip
    end
end