class GetEnsemblData

    require 'net/http'
    require 'uri'
    require 'json'

    require 'byebug' # FIXME

    attr_reader :release

    def initialize(outfile)
        @file = outfile
        @release = get_release

        @gene_prefix = "ENSG"
        @transcript_prefix = "ENST"
    end

    def get_genes
# TODO
    end

    def get_transcripts
        puts "Getting transcript ids ..."
        @ids = get_ids("transcript")

        puts "Getting transcripts ..."
        introns_masked = get_sequences("introns")
        utrs_masked = get_sequences("utrs")

        puts "Parsing transcripts, determining exons, introns, utr regions ..."
        @ids_with_sequences = parse_sequences(introns_masked, utrs_masked)

        @ids_with_sequences
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

    def get_ids(kind)
        # NOTE: no idea how to retrieve this information using the REST-API...
        # instead: using an XML query generated with BioMart

        if kind == "transcript"
            filter = "transcript_biotype"
            attribute = "ensembl_transcript_id"
            prefix = @transcript_prefix
        else
            # kind == gene!
            filter = "biotype"
            attribute = "ensembl_gene_id"
            prefix = @gene_prefix
        end

        path = "http://www.ensembl.org/biomart/martservice?"
        request = "\'query=<!DOCTYPE Query><Query  virtualSchemaName = \"default\" formatter = \"CSV\" header = \"0\" uniqueRows = \"1\" count = \"\" datasetConfigVersion = \"0.6\" ><Dataset name = \"hsapiens_gene_ensembl\" interface = \"default\" ><Filter name = \"#{filter}\" value = \"protein_coding\"/><Attribute name = \"#{attribute}\" /></Dataset></Query>\'"
        response = %x[curl -s -d #{request} #{path}]

        # filter: accepting only lines starting with correct prefix. enforce uniqueness
        response.split("\n").select{|str| str.start_with?(prefix)}.uniq
    end

    def get_sequences(type)
        log_progress

        if type == "introns"
            request_type = "genomic" # causes "mask_feature" to mask introns
        else
            # type == utrs!
            request_type = "cdna" # causes "mask_feature" to mask utrs
        end

        response_type = 'text/plain'
        # @ids.collect do |id| FIXME
        @ids[0..100].collect do |id|
            log_progress

            path = "/sequence/id/#{id}?mask_feature=1;type=#{request_type};"
            request_from_ensembl_rest_server(path, response_type)
        end
    end

    def parse_sequences(introns_masked, utrs_masked)
        parsed = {}
        @ids.each_with_index do |id, ind|

            # NOTE: these exons contain 5' and 3' UTR (if annotated)
            # these utrs will not contain intronic sequence
            exons, introns = get_exons_and_introns(introns_masked[ind])
            utr5, utr3 = get_utrs(utrs_masked[ind])

            fiveprime_utr, unspliced_transcript, threeprime_utr =  adjust_to_own_definitions(exons, introns, utr5, utr3)

debugger if fiveprime_utr.is_lower? || threeprime_utr.is_lower?
puts id
# TODO
# debug:
# - utr contains an intron: -> is the utr seq. correct???
    # test-case for intron in utr3: ENST00000627758
    # test-case for intrin in utr5: ENST00000630425
# - is gene starting with atg? ending with stopcodon?
    # stopcodon :
        # utr3[0] would make stopcodon complete (ENST00000628983)
        # stopcodon is complete (ENST00000627423)


# TODO: verify-method
            parsed[id] = {
                fiveprime_utr: fiveprime_utr,
                unspliced_transcript: unspliced_transcript,
                threeprime_utr: threeprime_utr
            }
        end
        parsed
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
                # TODO - solange im code lassen bis einmal ueber alle transcripte gelaufen ohne in diesem else gelandet zu sein.
                # gleiches gilt fuer TODO in utr3-schleife.
                debugger
                puts  "??"
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
                debugger
                puts "??"
            end
        end

        exons_introns_cleaned = exons.zip(introns).flatten.compact.join("")
        [utr5_cleaned, exons_introns_cleaned, utr3_cleaned]
    end

    def split_seq_by_case(seq)
        CoreExtensions::Settings.setup
        to_gene_obj = ToGene::FastaToGene.new("dummy")
        data = GeneToFasta.new("dummy", seq).fasta.lines.map{|line| line.chomp}
        to_gene_obj.parse_gene_record(data)
        [to_gene_obj.exons, to_gene_obj.introns]
    end

    def verify_transcripts
# TODO
# rewrite this. use keep_if on @ids_with_sequences. use multipel conditions.

        # delete transcript_ids if corresponding gene_seq is false
        @transcript_ids.keep_if.each_with_index{|str, ind| @transcript_seqs[ind] }
        # delete transcript_seqs if no sequence exists (seq is not true)
        @transcript_seqs.keep_if{|str| str }
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