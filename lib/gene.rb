class Gene

    def initialize(file)
        @path = file
        @translation = nil
        @descriptions = []
        @exons = []
        @introns = []

        parse_file
        convert_exons_and_introns_to_upper_case

        ensure_exon_and_intron_numbers_match_specification
        ensure_exon_translation_matches_given_translation if @translation
    end

    def tweak_exons
        @exons = @exons.map do |exon|    
            is_tweak_first_half = false
            is_tweak_second_half = false
            if is_first_exon_to_tweak?(exon)
                is_tweak_second_half = true

            elsif is_last_exon_to_tweak?(exon)
                is_tweak_first_half = true

            elsif is_exon_not_to_tweak?(exon)
            else
                is_tweak_first_half = true
                is_tweak_second_half = true

            end
           
            destroy_ese_motifs(exon, is_tweak_first_half, is_tweak_second_half)
        end
    end

    private

    def parse_file
        # parse file assuming a certain format
        if successfully_parsed_genebank_file 

        elsif successfully_parsed_fasta_file

        else
            # ops. neither genebank nor fasta file?!
            abort "Unrecognized file format: #{@path}."\
                "Input has to be either a GeneBank record or "\
                "a FASTA file containing exons and introns."
        end
    end

    def convert_exons_and_introns_to_upper_case
        @exons = @exons.map{ |e| e.upcase }
        @introns = @introns.map{ |i| i.upcase }
    end

    def ensure_exon_and_intron_numbers_match_specification
        n_exons = @exons.size
        n_introns = @introns.size

        # a proper gene has at least one exon to tweak
        # and is of format: exon-intron[-exon-intron]*-exon
        if n_exons < Constants.minimum_number_of_exons
            abort "Nothing to do: Must leave all #{n_exons} exons intact."
        end

        if n_exons != n_introns + 1
            abort "Invalid gene format: There should be one exon more than introns."
        end
    end

    def ensure_exon_translation_matches_given_translation
        joined_exons = @exons.join("")
        translated_exon = AminoAcid.translate(joined_exons)
        if @translation != translated_exon
            abort "Invalid gene format: Specified translation does not match translated exons."
        end
    end

    def successfully_parsed_genebank_file
        sequence = nil
        exon_positions = []
# todo: 
#  nicht exons parsen, weil die nicht immer da sein muessen. besser: cds/gene parsen
#  falls >1 cda: liste aller genename sammeln & ausgeben, dass dann das gen spezifiert werden muss. 
# todo: optional argument: genename
# todo: falls optional argument: nach diesem gen suchen in fasta (!) und genbank. falls nicht gefunden, gesonderte fehlermeldugn ausgeben!

# - save seq in @translation
        is_feature = false
        is_sequence = false
        IO.foreach(@path) do |line|
            # new description started
            if 
                # howto find desc. line: starts with char. only uppercase chars
                is_feature = false
                is_sequence = false 
            end
            line = line.strip

            if line == "FEATURES"
                is_feature = true
            end
            if line == "ORIGIN" 
                is_sequence = true
            end

        end

        are_exons_and_introns_found
    end

# sanity check: translate gene & check if transl is same as the noted one!!!
# only for genebank file; no transl given in fasta


    def successfully_parsed_fasta_file
        last_seq = nil

        IO.foreach(@path) do |line|
            line = line.chomp
            if line.start_with?(">") 
                str_wo_leading_char = line.sub(">", "")
                @descriptions.push(str_wo_leading_char)
            else       
                sequences = split_into_upper_and_lower_case(line)
                sequences.each do |seq|
                    if seq.is_upper? 
                        if last_seq && last_seq.is_upper?
                            updated_last_element = @exons.pop + seq
                            @exons.push(updated_last_element)
                        else
                            @exons.push(seq)
                        end
                    else
                        if last_seq && last_seq.is_lower?
                            updated_last_element = @introns.pop + seq
                            @introns.push(updated_last_element)
                        else
                            @introns.push(seq)
                        end
                    end
                    last_seq = seq
                end
            end
        end

        are_exons_and_introns_found
    end

    def are_exons_and_introns_found
        # check file format the duck-typing way...
        # a proper genebank/fasta-file specifies descriptions, exons and introns
        @exons.any? && @introns.any? && @descriptions.any?
    end

    # helper method to parse fasta-file
    def split_into_upper_and_lower_case(str)
        parts = []
        last_char = nil
        str.each_char do |char|
            if char.is_upper?
                if last_char && last_char.is_upper? 
                    updated_last_element = parts.pop + char
                    parts.push(updated_last_element)
                else
                    parts.push(char)
                end
            else
                if last_char && last_char.is_lower?
                    updated_last_element = parts.pop + char
                    parts.push(updated_last_element)
                else
                    parts.push(char)
                end
            end
            last_char = char
        end
        parts
    end

    def is_first_exon_to_tweak?(exon)
        ( Constants.keep_first_intron? && exon_index(exon) == 1 ) ||
            ( ! Constants.keep_first_intron? && exon_index(exon) == 0 )
    end

    def is_last_exon_to_tweak?(exon)
        exon_index(exon) == @exons.size - 1
    end

    def is_exon_not_to_tweak?(exon)
        Constants.keep_first_intron? && exon_index(exon) == 0
    end

    def exon_index(exon)
        @exons.index(exon)
    end

    def destroy_ese_motifs(exon, is_tweak_first_half, is_tweak_second_half)
# TODO
# eigene klasse sequence tweaker? 
# kriegt seq., aendert sie & gibt sie zurueck!
# sollte auch die berechnugn, welche pos zu tweaken, selber machen!!! 
        n_nucleotides = exon.size
        if is_tweak_first_half 
            start_pos = 0
            stop_pos = 
                if n_nucleotides < 2 * Constants.number_of_nucleotides_to_tweak 
                    n_nucleotides / 2
                else
                    Constants.number_of_nucleotides_to_tweak
                end
            puts "#{start_pos} - #{stop_pos}"
        end
        if is_tweak_second_half
            start_pos = 
                if n_nucleotides < 2 * Constants.number_of_nucleotides_to_tweak 
                    n_nucleotides / 2
                else
                    n_nucleotides - Constants.number_of_nucleotides_to_tweak
debugger
puts "??"

                end
            stop_pos = exon.size - 1
            puts "#{start_pos} - #{stop_pos}"
        end
        puts ""
        exon 
    end
end