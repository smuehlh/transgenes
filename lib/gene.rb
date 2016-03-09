class Gene

    def initialize(file)
        @path = file
        @translation = ""
        @descriptions = []
        @exons = []
        @introns = []

        parse_file
        convert_exons_and_introns_to_upper_case

        ensure_exon_and_intron_numbers_match_specification
        ensure_exon_translation_matches_given_translation if ! @translation.empty?
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
        # determine file format

        # file is either in genebank or in fasta format.
        filename, extension = FileHelper.split_filename_and_extension(@path)   
        if [".gb"].include?(extension.downcase)
            parse_genebank_file
        elsif [".fasta", ".fa", ".fas"].include?(extension.downcase)
            parse_fasta_file
        else
            # ops. neither genebank nor fasta file?!
            abort "Unrecognized file format: #{@path}.\n"\
                "Input has to be either a GeneBank record or "\
                "a FASTA file containing exons and introns."
        end

        if ! are_exons_and_introns_found
            # ops. extension was not too informative.
            abort "Unrecognized file format: #{@path}.\n"\
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

    def translate_exons
        joined_exons = @exons.join("")
        AminoAcid.translate(joined_exons)
    end

    def ensure_exon_translation_matches_given_translation
        if @translation != translate_exons
            abort "Invalid gene format: Specified translation does not match translated exons."
        end
    end

    def parse_genebank_file
        complete_dna_sequence = ""
        exon_positions_in_dna = []

        # remember current field to access all lines of multi-line fields.
        field = "" 
        nested_features_field = ""
        nested_cds_features_field = ""

        whitespaces_other_than_newline_regexp = '[^\S\n]+'
        capture_uppercase_string_regexp = '([A-Z]+)'
        cds_field_exon_position_regexp = 'CDS\s+.*\d'
        cds_field_unspecific_key_value_regexp = '\/\w+='
        capture_unspecific_key = '\/(\w+)='

        IO.foreach(@path) do |line|
            if this_field = line[/^#{capture_uppercase_string_regexp}/, 1]
                field = this_field
                next
            end
            # INFO
            # don't line.strip here to leave white space intact for checking nested fields

            if field == "FEATURES" 
                # require blanks/tabs before AND after to ensure not to match a sequence translation
                if this_nested_field = line[
                    /
                        ^ # beginning of the line
                        #{whitespaces_other_than_newline_regexp}
                        #{capture_uppercase_string_regexp}
                        #{whitespaces_other_than_newline_regexp}
                    /x, 1
                    ]
                    nested_features_field = this_nested_field
                end

                line = line.strip            
                if nested_features_field == "CDS"
                    if this_nested_field = line[
                        /
                            ^ # beginning of the line
                            (
                                #{cds_field_unspecific_key_value_regexp}
                                |
                                #{cds_field_exon_position_regexp}
                            ) # alternative
                        /x, 1
                        ]
                        nested_cds_features_field = 
                            extract_field_from_cds_line(
                                line,
                                cds_field_exon_position_regexp, 
                                cds_field_unspecific_key_value_regexp
                            )
                    end

                    feature = extract_feature_from_cds_line(line, cds_field_exon_position_regexp, cds_field_unspecific_key_value_regexp)

                    if nested_cds_features_field == "exon-position" 
                        puts feature
                        exon_positions_in_dna = convert_to_numerical_position_list(feature)
                    elsif nested_cds_features_field == "gene" 
                        @descriptions.push(feature)
                    elsif nested_cds_features_field == "translation" 
                        @translation += feature
                    end                      
                end
            end
            if field == "ORIGIN"
                line = line.strip

                seq_wo_invalid_chars = line.gsub(/[^a-zA-Z]/, "")
                complete_dna_sequence += seq_wo_invalid_chars
            end
        end

        # collect exons and introns
        exon_positions_in_dna.each do |exon_start, exon_stop|
            @exons.push(complete_dna_sequence[exon_start..exon_stop])

            exon_index = @exons.size - 1
            next_exon_index = exon_index + 1

            # all but last exon are followed by an intron
            if next_exon_positions = exon_positions_in_dna[next_exon_index]
                intron_start = exon_stop + 1
                intron_stop = next_exon_positions.last

                @introns.push(complete_dna_sequence[intron_start..intron_stop])
            end
        end
    end

    def parse_fasta_file
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

        # TODO
        # translate exons & save as @translations
        # remove 'if @translations.empty?' from above!
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