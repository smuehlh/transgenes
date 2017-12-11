class PagesController < ApplicationController
    def contact
    end

    def help
        @archive = ZipStandalone.get_archive_name
    end

    def download
        @main = ZipStandalone.get_main_filename_in_zip
        @archive = ZipStandalone.get_archive_name
    end

    def get_standalone_tool
        data = ZipStandalone.zip
        filename = Dir::Tmpname.make_tmpname(
            [ZipStandalone.get_archive_name, ".zip"], nil
        )
        send_data(data, type: 'application/zip', filename: filename)
    end
end
