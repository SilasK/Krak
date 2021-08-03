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






## Create custom kraken + braken dbs
Custom kraken db's can be generated using flexitaxd.
