
import os

snakemake_folder= os.path.dirname(workflow.snakefile)
# use default config
configfile: os.path.join(snakemake_folder,'config.yaml')


localrules: flextaxd_createdb
rule build_kraken_db:
    input:
        db="taxonomy/flextaxd/flextaxd.ftd",
        nodes= "taxonomy/flextaxd/nodes.dmp",
        names= "taxonomy/flextaxd/names.dmp",
        genome_folder = config['genome_folder']
    output:
        expand("kraken_db/{file}",file=["hash.k2d", "opts.k2d","seqid2taxid.map","taxo.k2d"]),
        directory("kraken_db/taxonomy"),
        directory("kraken_db/library")
    params:
        taxonomy= "taxonomy/flextaxd",
        kraken_path= os.path.abspath("kraken_db")
    conda:
        "envs/kraken.yaml"
    threads:
        32
    resources:
        mem=512,
        time=12
    threads:
        5
    resources:
        mem=12,
        time=1
    benchmark:
        "log/benchmark/build_krken_db.tsv"
    log:
        "log/kraken/build_krken_db.log"
    shell:
        "flextaxd-create "
        "--db_name {params.kraken_path} "
        "--database {input.db} "
        "-o {params.taxonomy} "
        " --genomes_path {input.genome_folder} "
        "-p {threads} "
        " --create_db --dbprogram kraken2 "
        "--log log/kraken --verbose --debug &> {log}"

rule flextaxd_createdb:
    input:
        config['taxonomy']
    output:
        db="taxonomy/flextaxd/flextaxd.ftd",
        nodes= "taxonomy/flextaxd/nodes.dmp",
        names= "taxonomy/flextaxd/names.dmp"
    params:
        out_path= "taxonomy/flextaxd/"
    conda:
        "envs/kraken.yaml"
    log:
        "log/flextaxd/create_db.log"
    shell:
        "flextaxd "
        "--taxonomy_file {input} "
        "--taxonomy_type QIIME "
        "--force --verbose "
        "--database {output.db} "
        "--logs log/flextaxd/ "
#        "--genomeid2taxid taxonomy/genomeid2taxname.tsv "
        " 2> {log} ; "
        #"flextaxd --database {output.db} --validate  2>> {log} ; "
        "flextaxd --dump --outdir {params.out_path} "
        "--dbprogram kraken2 "
        "--database {output.db} --verbose "
        " --logs log/flextaxd/  2>> {log}"



#--test





# kraken2 --db kraken_db --report ERP002061_fastq/ERR210758.report ERP002061_fastq/ERR210758.fq.gz --output - --threads
#bracken https://ccb.jhu.edu/software/bracken/index.shtml?t=manual

# bracken=2.6
# bracken-build -l 50  -d kraken_db/  -t 1

# braken doesn not respect -r argument!!

# Usage: kraken2 [options] <filename(s)>
#
# Options:
#   --db NAME               Name for Kraken 2 DB
#                           (default: none)
#   --threads NUM           Number of threads (default: 1)
#   --quick                 Quick operation (use first hit or hits)
#   --unclassified-out FILENAME
#                           Print unclassified sequences to filename
#   --classified-out FILENAME
#                           Print classified sequences to filename
#   --output FILENAME       Print output to filename (default: stdout); "-" will
#                           suppress normal output
#   --confidence FLOAT      Confidence score threshold (default: 0.0); must be
#                           in [0, 1].
#   --minimum-base-quality NUM
#                           Minimum base quality used in classification (def: 0,
#                           only effective with FASTQ input).
#   --report FILENAME       Print a report with aggregrate counts/clade to file
#   --use-mpa-style         With --report, format report output like Kraken 1's
#                           kraken-mpa-report
#   --report-zero-counts    With --report, report counts for ALL taxa, even if
#                           counts are zero
#   --memory-mapping        Avoids loading database into RAM
#   --paired                The filenames provided have paired-end reads
#   --use-names             Print scientific names instead of just taxids
#   --gzip-compressed       Input files are compressed with gzip
#   --bzip2-compressed      Input files are compressed with bzip2
#   --minimum-hit-groups NUM
#                           Minimum number of hit groups (overlapping k-mers
#                           sharing the same minimizer) needed to make a call
#                           (default: 2)
#   --help                  Print this message
#   --version               Print version information
