# Snakemake pipline for Kraken2 + Braken.

## Classify using existing kraken2 + braken dbs


Install Snakemake using [conda](https://conda.io/projects/conda/en/latest/user-guide/install/index.html):

    conda create -c bioconda -c conda-forge -n kraken snakemake

    conda activate snakemake

For installation details, see the [instructions in the Snakemake documentation](https://snakemake.readthedocs.io/en/stable/getting_started/installation.html).


2. generate a sample table from your fastq files:

        scripts/generate_sample_table.py path/to/fastqs


Check the generated samples.tsv and simplify names, if you wish.

3. Run the Pipeline.

a. First make a dryrun

      snakemake  -s Kraken/workflow/classify.smk --use-conda --dryrun


  If you have access to cluster or cloud we recommend you to setup cluster/cloud integration via a profile.
  See the [Snakemake documentation](https://snakemake.readthedocs.io/en/stable/executable.html) for further details.

  b. Run the Pipeline:

    snakemake  -s Kraken/workflow/classify.smk --use-conda --dryrun



## Use databases for human and mouse gut

Download the Kraken db for human and put them in `Kraken_dbs/UHGG`:

    wget https://ezmeta.unige.ch/CMGM/v1/UHGG_v1_kraken2_db.tar.gz
    tar -xzf UHGG_v1_kraken2_db.tar.gz -C Kraken_dbs/UHGG --strip-components 1

Set the path to the downloaded kreken db in the `Kraken/config.yaml`.



## Create custom kraken + braken dbs
Custom kraken db's can be generated using flexitaxd.

You need flextaxd to build Kraken dbs. There is an error in the latest version https://github.com/FOI-Bioinformatics/flextaxd/issues/48, therfore run

    mamba install flextaxd=0.3.5
    
    
 What you need to build a kraken db is:
  - all genomes in folder
  - a greeen genes formated taxonomy file
  
Modify the name of your database as well as the path for building in the `config.file` 

The taxonomy file should be a tsv file of the fomrat:
```
GUT_GENOME000047        d__Bacteria;p__Proteobacteria;c__Gammaproteobacteria;o__Enterobacterales;f__Enterobacteriaceae;g__Enterobacter;s__Enterobacter mori
GUT_GENOME000565        d__Bacteria;p__Proteobacteria;c__Gammaproteobacteria;o__Enterobacterales;f__Enterobacteriaceae;g__Kluyvera;s__Kluyvera sp902363335
```

You can got down to subspecies level using the `x__` prefix
If you want to quantify on subspecies/strain level you should add `subsp` to the list of levels to be quantified.


## Genome length normalisation
This needs to be done. 
Kraken + Braken attributes reads to species (or the level you want) however it doesn't normalize it to genome size. Larger genomes get more reads. While this is no problem for ratio based analyses (CoDa) it biases relative abundance calculation. 
