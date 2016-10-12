namespace :ensembl do
    namespace :codon_probabilities do

        desc "Calculate codon probability matrix for one-exon genes"
        task one_exon_genes: :environment do
            require File.join(Rails.root, 'lib', 'standalone', 'lib', 'genetic_code.rb')

            # init third-site counts
            counts = {
                two_fold_degenerate: { t: {}, c: {}, a: {}, g: {} },
                three_fold_degenerate: { t: {}, c: {}, a: {} },
                four_fold_degenerate: { t: {}, c: {}, a: {}, g: {} },
                six_fold_twosub_degenerate: { t: {}, c: {}, a: {}, g: {} },
                six_fold_foursub_degenerate: { t: {}, c: {}, a: {}, g: {} }
            }

            EnsemblGene.find_each do |gene|
                parsed_gene = parse_gene(gene)
                next unless parsed_gene # parsing was unsuccessfull
                # TODO: next if not a 1-exon gene

                codons = GeneticCode.split_cdna_into_codons(parsed_gene[:exons].join(""))
                codons.each_with_index do |codon, pos_in_gene|
                    next if GeneticCode.is_stopcodon(codon)
                    next if GeneticCode.is_single_synonymous_codon(codon)

                    codon_degeneracy = select_codon_degeneracy(codon)
                    last_nt = get_last_nucleotide(codon)
                    update_counts(counts, codon_degeneracy, last_nt, pos_in_gene)
                end
            end

            # save counts
            fh = File.open(
                File.join(
                    Rails.root, 'lib', 'standalone', 'lib', 'scores', "third_site_counts-ensembl-v#{EnsemblGene.first.version}.rb"
                ), "w"
            )
            fh.print "Third_site_counts = "
            fh.print counts
            fh.close
        end

        def parse_gene(gene)
            gene_parser = WebinputToGene.new(
                # mimic webinput
                {name: "CDS", data: gene.to_fasta}, false
            )
            # NOTE: there should be only one gene record. therefore, taking the first should be save. a record consists of starting line and data. take data only
            gene_parser.get_records.values.first
        end

        def select_codon_degeneracy(codon)
            n_syn_codons = GeneticCode.get_synonymous_codons(codon).size
            if n_syn_codons == 2
                :two_fold_degenerate
            elsif n_syn_codons == 3
                :three_fold_degenerate
            elsif n_syn_codons == 4
                :four_fold_degenerate
            elsif n_syn_codons == 6
                n_syn_codons_same_box = GeneticCode.get_synonymous_codons_in_codon_box(codon).size
                if n_syn_codons_same_box == 2
                    :six_fold_twosub_degenerate
                else
                    :six_fold_foursub_degenerate
                end
            end
        end

        def get_last_nucleotide(codon)
            codon.last.downcase.to_sym
        end

        def update_counts(counts, codon_degeneracy, last_nt, pos_in_gene)
            begin
            counts[codon_degeneracy][last_nt][pos_in_gene] = 0 unless counts[codon_degeneracy][last_nt][pos_in_gene]
            rescue
                debugger
                puts "??"
            end
            counts[codon_degeneracy][last_nt][pos_in_gene] += 1
        end
    end
# TODO: warum faengt ENSG00000000003 nicht mit ATG an ???
end