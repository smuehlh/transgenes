class SynonymousSitesToKeepToGene

    attr_reader :sites_to_keep

    def self.init_and_parse(file)
        obj = SynonymousSitesToKeepToGene.new
        obj.parse_file_or_die(file)
        obj.sites_to_keep
    end

    def initialize
        # parse sites to keep. be verbose.
        @sites_to_keep = []
        $logger.debug("Parsing sites to keep intact input. Expecting to find sequence positions.")
    end

    def parse_file_or_die(file)
        @file_info = "#{file} (Attempting to read synonymous sites to keep)"
        ensure_file_is_not_empty(file)
        parse_sites_and_ensure_site_format(file)

    rescue StandardError => exp
        # something went very wrong. most likely the input file is corrupt.
        ErrorHandling.abort_with_error_message(
            "invalid_site_to_keep_format", "SynonymousSitesToKeepToGene", @file_info
        )
    end

    private

    def ensure_file_is_not_empty(file)
        ErrorHandling.abort_with_error_message(
            "empty_file", "SynonymousSitesToKeepToGene", @file_info
        ) if FileHelper.file_empty?(file)
    end

    def parse_sites_and_ensure_site_format(file)
        parse_sites(file)
        ensure_sites_are_parsed_successfully
    end

    def parse_sites(file)
        IO.foreach(file) do |line|
            line = line.chomp
            # sites are in human counting, convert to ruby-counting
            @sites_to_keep.push line.to_i - 1 unless line.empty?
        end
        @sites_to_keep.uniq!
        $logger.debug("Identified #{@sites_to_keep.size} sites to keep intact.")
    end

    def ensure_sites_are_parsed_successfully
        @sites_to_keep.each do |site|
            unless is_valid_site(site)
                $logger.debug("Invalid synonymous sites: #{site}")
                ErrorHandling.abort_with_error_message(
                    "invalid_site_to_keep_format", "SynonymousSitesToKeepToGene", @file_info
                )
            end
        end
    end

    def is_valid_site(site)
        # synonymous sites should be 2,5,8, ...
        (site + 1) % 3 == 0
    end
end