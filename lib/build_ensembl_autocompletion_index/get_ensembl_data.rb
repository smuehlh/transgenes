class GetEnsemblData

    require 'net/http'
    require 'uri'
    require 'json'

    attr_reader :release

    def initialize(outfile)
        @file = outfile
        @release = get_release
        @transcript_prefix = "ENST"
    end

    def get_transcripts
        @fh = File.open(@file, "w")

        puts "Getting transcript ids ..."
        @ids = get_ids

        puts "Getting transcripts ..."
        @ids.each do |id|
            introns_masked = get_sequence("introns", id)
            utrs_masked = get_sequence("utrs", id)
            next unless introns_masked && utrs_masked
            utr5, exons_introns, utr3 = parse_sequences(introns_masked, utrs_masked)
            write_to_file(id, utr5, exons_introns, utr3)
        end
        @fh.close
    end

    at_exit do
        @fh.close if @fh
    end

    private

    def get_release
        path = '/info/data/?'
        response_type = 'application/json'

        result = request_from_ensembl_rest_server(path, response_type)
        if result
            json = JSON.parse(result)
            json["releases"].join("/")
        else
            return ""
        end
    end

    def get_ids
        # NOTE: no idea how to retrieve this information using the REST-API...
        # instead: using an XML query generated with BioMart

        filter = "transcript_biotype"
        attribute = "ensembl_transcript_id"
        prefix = @transcript_prefix

        path = "http://www.ensembl.org/biomart/martservice?"
        request = "\'query=<!DOCTYPE Query><Query  virtualSchemaName = \"default\" formatter = \"CSV\" header = \"0\" uniqueRows = \"1\" count = \"\" datasetConfigVersion = \"0.6\" ><Dataset name = \"hsapiens_gene_ensembl\" interface = \"default\" ><Filter name = \"#{filter}\" value = \"protein_coding\"/><Attribute name = \"#{attribute}\" /></Dataset></Query>\'"
        response = %x[curl -s -d #{request} #{path}]

        # filter: accepting only lines starting with correct prefix. enforce uniqueness
        response.split("\n").select{|str| str.start_with?(prefix)}.uniq
    end

    def get_sequence(type, id)
        log_progress
        sleep(1/15.0) # don't send more than 15 requests per second ...

        # cause "mask_feature" to mask introns or utrs, respectively
        request_type = type == "introns" ? "genomic" : "cdna"
        response_type = 'text/plain'

        path = "/sequence/id/#{id}?mask_feature=1;type=#{request_type};"
        request_from_ensembl_rest_server(path, response_type)
    end

    def parse_sequences(introns_masked, utrs_masked)
        # NOTE: these exons contain 5' and 3' UTR (if annotated)
        # these utrs will not contain intronic sequence
        exons, introns = get_exons_and_introns(introns_masked)
        utr5, utr3 = get_utrs(utrs_masked)

        fiveprime_utr, unspliced_transcript, threeprime_utr =  adjust_to_own_definitions(exons, introns, utr5, utr3)
        # NOTE: for some genes, the retrieved 3'UTR contains the last amino acid of the stop codon (it is displayed correctly on Ensembl)
        # This does not seem to happen for the 5'UTR and the start codon
        fix_stopcodon_if_neccessary_and_possible(unspliced_transcript, threeprime_utr)

        [fiveprime_utr, unspliced_transcript, threeprime_utr]
    end

    def get_exons_and_introns(seq)
        # uppercase = exons (+ utr...), lowercase = introns
        to_gene_exons, to_gene_introns = split_seq_by_case(seq)
        [to_gene_exons, to_gene_introns]
    end

    def get_utrs(seq)
        # uppercase = cds, lowercase = utrs
        # first intron = 5'utr, second intron = 3'utr. BUT: one or both might be missing
        to_gene_uppercase, to_gene_lowercase = split_seq_by_case(seq)
        putative_utr5 = to_gene_lowercase.first
        putative_utr3 = to_gene_lowercase.last

        utr5 =
            if putative_utr5 && seq.downcase.start_with?(putative_utr5)
                putative_utr5.upcase
            else
                ""
            end
        utr3 =
            if putative_utr3 && seq.downcase.end_with?(putative_utr3)
                putative_utr3.upcase
            else
                ""
            end

        [utr5, utr3]
    end

    def adjust_to_own_definitions(exons, introns, utr5, utr3)
        # exons should be coding sequences only, no utrs
        # utrs should contain introns, too (if applicable)
        utr5_cleaned, exons_introns_cleaned, utr3_cleaned = "", "", ""
        done = false
        until done do
            if utr5.blank?
                # no utr: nothing to do
                done = true
            elsif exons.first == utr5.first(exons.first.size)
                # INFO: this compares exons.first with the first N chars of utr5
                # exon is completely utr: update exons, introns, and cleaned utr
                exon = exons.shift
                intron = introns.shift
                utr5_cleaned += exon + intron
                utr5 = utr5.sub!(exon, "")
                done = false
            elsif exons.first.start_with?(utr5)
                # exon is partly utr: update exons and cleaned utr
                exons.first.sub!(utr5, "")
                utr5_cleaned += utr5
                done = true
            else
                # should never happen
                puts "cannot adjust sequences: #{exons.first}, #{utr5}"
                done = true
            end
        end

        done = false
        until done do
            if utr3.blank?
                # no utr: nothing to do
                done = true
            elsif exons.last == utr3.last(exons.last.size)
                # INFO: this compares exons.last with the last N chars of utr3
                # exon is completely utr: update exons, introns, and cleaned utr
                exon = exons.pop
                intron = introns.pop
                utr3_cleaned = intron + exon + utr3_cleaned
                utr3 = utr3.chomp!(exon)
                done = false
            elsif exons.last.end_with?(utr3)
                # exon is partly utr: update exons and cleaned utr
                exons.last.chomp!(utr3)
                utr3_cleaned = utr3 + utr3_cleaned
                done = true
            else
                # should never happen
                puts "cannot adjust sequences: #{exons.last}, #{utr3}"
                done = true
            end
        end

        exons_introns_cleaned = exons.zip(introns).flatten.compact.join("")
        [utr5_cleaned, exons_introns_cleaned, utr3_cleaned]
    end

    def fix_stopcodon_if_neccessary_and_possible(exons_introns, utr3)
        if ! GeneticCode.is_stopcodon(exons_introns.last(3))
            # it's neccessary

            last_codon_when_fixed = exons_introns.last(2) + utr3.first
            if ! utr3.blank? && GeneticCode.is_stopcodon(last_codon_when_fixed)
                # it's possible
                exons_introns = exons_introns + utr3.first
                utr3 = utr3[1..-1]
            end
        end
        [exons_introns, utr3]
    end

    def write_to_file(id, utr5, exons_introns, utr3)
        @fh.puts GeneToFasta.new("#{id} 5'UTR", utr5).fasta
        @fh.puts GeneToFasta.new("#{id} CDS", exons_introns).fasta
        @fh.puts GeneToFasta.new("#{id} 3'UTR", utr3).fasta
    end

    def split_seq_by_case(seq)
        CoreExtensions::Settings.setup
        to_gene_obj = ToGene::FastaToGene.new("dummy")
        data = GeneToFasta.new("dummy", seq).fasta.lines.map{|line| line.chomp}
        to_gene_obj.parse_gene_record(data)
        [to_gene_obj.exons, to_gene_obj.introns]
    end

    # returns false if an error occured
    def request_from_ensembl_rest_server(path, response_type)
        server = 'http://rest.ensembl.org'
        url = URI.parse(server)
        http = Net::HTTP.new(url.host, url.port)
        request = Net::HTTP::Get.new(
            path, {'Content-Type' => response_type}
        )
        response = http.request(request)

        if response.code != "200"
            puts "Invalid response: #{response.code}"
            puts response.body

            return false
        end

        response.body
    end

    def log_progress
        @progress = @progress ? @progress + 1 : 0
        puts "#{@progress} / #{@ids.size}" if is_logging_interval
    end

    def is_logging_interval
        @progress % 10_000 == 0
    end
end