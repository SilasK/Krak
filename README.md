# Simple snakemake pipline for Kraken2 + Braken.

Running kraken+ braken can be a bit combersome. Here is *Krak* a simple plpeline that let's you run these tools in a simple and efficient way. 

## Classify using existing kraken2 + braken dbs

Download git repository:
    git clone https://github.com/SilasK/Krak

Install Snakemake using [conda](https://conda.io/projects/conda/en/latest/user-guide/install/index.html):

    conda create -c bioconda -c conda-forge -n kraken snakemake

    conda activate kraken

For installation details, see the [instructions in the Snakemake documentation](https://snakemake.readthedocs.io/en/stable/getting_started/installation.html).


2. generate a sample table from your fastq files:

        krak/scripts/generate_sample_table.py path/to/fastqs


Check the generated samples.tsv and simplify names, if you wish.

3. Run the Pipeline.

a. First make a dryrun

      snakemake  -s krak/workflow/classify.smk --use-conda --dryrun


  If you have access to cluster or cloud we recommend you to setup cluster/cloud integration via [our profile](https://github.com/Snakemake-Profiles/generic). 
  See the [Snakemake documentation](https://snakemake.readthedocs.io/en/stable/executable.html) for further details.

  b. Run the Pipeline:

    snakemake  -s krak/workflow/classify.smk --use-conda 



## Use databases for human and mouse gut

Download the Kraken db for human and put them in `Kraken_dbs/UHGG`:

    db="uhgg" # for human "cmmg" for mouse"
    mkdir -p databases/$db
    
    for file in database100mers.kmer_distrib
                database150mers.kmer_distrib
                database200mers.kmer_distrib
                database250mers.kmer_distrib
                database50mers.kmer_distrib
                database75mers.kmer_distrib
                hash.k2d
                inspect.txt.gz
                opts.k2d
                seqid2taxid.map.gz
                taxo.k2d ; 
    do 
        wget https://ezmeta.unige.ch/CMMG/Kraken2db/$db/$file -O databases/$db/$file
    done

    

Set the path to the downloaded kraken db in the `Kraken/config.yaml`.


## Analyze the microbiome based on taxonomy and Kegg modules

Once you have the Kraken2 quantification you can use this [jupyter notebook](https://colab.research.google.com/github/trajkovski-lab/CMMG/blob/main/notebooks/Analyze-cold-adapted-microbiota.ipynb) that shows how CMMG can be used for the functional and taxonomic analysis of mouse metagenome data.


## Create custom kraken + braken dbs
Custom kraken db's can be generated using flexitaxd.

You need flextaxd to build Kraken dbs. There is an error in the latest version https://github.com/FOI-Bioinformatics/flextaxd/issues/48, therfore run

    mamba install flextaxd=0.3.5
    
    
 What you need to build a kraken db is:
  - path to the top-level-folder with all genomes
  - a greeen genes formated taxonomy file

Genomes not in the taxonaomy are ignored. 
  
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
