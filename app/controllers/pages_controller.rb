class PagesController < ApplicationController
    def about
    end

    def contact
    end

    def help
    end

    def privacy
    end

    def download
    end

    def get_standalone_tool
        data = ZipStandalone.zip
        filename = Dir::Tmpname.make_tmpname ["sequenceOptimizer",".zip"], nil
        send_data(data, type: 'application/zip', filename: filename)
    end
end
