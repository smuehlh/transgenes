# README

transgenes is a standalone software to enhance mammalian transgenes through synonymous mutations. It is coupled to a basic [web interface](http://transgene-design.bath.ac.uk/).

This software has been developed at the Hurst lab, University of Bath, UK, as part of the Horizon 2020 project [Evolutionary genomics: new perspectives and novel medical applications (EvoGenMed)](https://cordis.europa.eu/project/id/669207).

## Standalone software

A software to make a gene work better as a transgene by introducing synonymous mutations to match site-specific codon usage in human one- or two-exon genes.

For more details, please visit [lib/standalone folder](./lib/standalone).

### Requirements

 - Ruby 2.4
 - Optionally: gem byebug

### Usage

```bash
ruby sequence_optimizer.rb
```

## Web interface

A basic rails web service for interacting with the sequence optimizer.

### Requirements

- Rails 4.2
- Ruby 2.4

### Deployment

```bash
rake assets:precompile # pre-compile assets
rake db:schema:load # prepare DB

rails s # start rails server
```

##  corvid19 branch

_or:_ Who doesn't like corvids over SARS-CoV-2?

In a surprising 2020 spin-off, we've adjusted our standalone tool to work in opposite direction: attenuate, rather than enhance, translation efficiency in humans.

When using this branch of our software, please cite:

> Alan M Rice, Atahualpa Castillo Morales, Alexander T Ho, Christine
> Mordstein, Stefanie Mühlhausen, Samir Watson, Laura Cano, Bethan
> Young, Grzegorz Kudla, Laurence D Hurst.
>  Evidence for Strong Mutation Bias toward, and Selection against, U Content in SARS-CoV-2: Implications for Vaccine Design
>   _Molecular Biology and Evolution_, msaa188,
> [https://doi.org/10.1093/molbev/msaa188](https://doi.org/10.1093/molbev/msaa188)

## License

[GNU GPL](./COPYING)
