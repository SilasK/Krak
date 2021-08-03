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

Set the path to the downloaded kreken db in the `Kraken/confiog.yaml`.



## Create custom kraken + braken dbs
Custom kraken db's can be generated using flexitaxd.
