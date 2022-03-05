# README

transgenes is a standalone software to enhance mammalian transgenes by introducing synonymous mutations to match site-specific codon usage in human one- or two-exon genes. It is coupled to a basic web interface.

This software has been developed at the Hurst lab, University of Bath, UK, as part of the Horizon 2020 project [Evolutionary genomics: new perspectives and novel medical applications (EvoGenMed)](https://cordis.europa.eu/project/id/669207).

This software is written in Ruby and Ruby on Rails. It can be invoked as a Ruby script via the command line or accessed through its web interface. The folder structure of this software project is that of a Ruby on Rails web application. Folders of note are:

 - [app/](./app): holding model, view, controller components of the web application
 - [app/assets/javascripts](./app/assets/javascripts): holding javascript files
 - [db/](./db): holding current database schema and migrations
 - [lib/standalone/](./lib/standalone): holding the standalone software
 - [lib/standalone/data](./lib/standalone/data): holding sample data

__Author__ Stefanie Mühlhausen
__Affiliation__ Laurence D Hurst
__Contact__ Laurence Hurst (l.d.hurst@bath.ac.uk)

This program comes with ABSOLUTELY NO WARRANTY

## Standalone software

A software to make a gene work better as a transgene by introducing synonymous mutations to match site-specific codon usage in human one- or two-exon genes.

For more details, please visit [lib/standalone folder](/smuehlh/transgenes/tree/corvid19/lib/standalone).
For more details, please visit [lib/standalone folder](../../tree/corvid19/lib/standalone).


### Requirements

 - Ruby 2.4
 - Optionally: gem byebug

### Usage

```bash
ruby sequence_optimizer.rb
```

## Web interface

[transgene-design](http://transgene-design.bath.ac.uk/) is a basic rails web service for interacting with the sequence optimizer.

### Requirements

- Rails 4.2
- Ruby 2.4
- SQLite 3

or, alternatively:
- Docker

### Deployment

```bash
rake assets:precompile # pre-compile assets
rake db:schema:load # prepare DB

rails s # start rails server
```

Alternatively, download the latest image from [docker hub](https://hub.docker.com/r/smuehlh/transgenes) and run it:
```bash
docker pull smuehlh/transgenes:<version>
docker run -p 80:80 smuehlh/transgenes:<version> # visit http://localhost:80
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
