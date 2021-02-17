include: "workflow_scripts.smk"
include: "sample_table.smk"

rule all:
    input:
        "classify_{db_name}"


#if paired otherwise change headers and --paired ioption.
rule kraken:
    input:
        reads=get_quality_controlled_reads , # returns paired end or not
        db= get_kraken_db_path,
        db_files = get_kraken_db_files
    output:
        #kraken="kraken_results/{db_name}/kraken_results/{sample}.kraken",
        report= "kraken_results/{db_name}/reports/{sample}.txt"
    log:
        "logs/run/{db_name}/{sample}.log"
    benchmark:
        "logs/benchmark/kraken/{db_name}/samples/{sample}.tsv"
    conda:
        "../envs/kraken.yaml"
    params:
        extra= config.get("kraken_run_extra",""),
        paired = '--paired' if config.get('paired_reads',True) else "" ,
    resources:
        mem= calculate_kraken_memory,
        time= config['classify_time']
    threads:
        config['kraken_threads']
    shell:
        """
            kraken2 \
            --db {input.db} \
            {params.extra} \
            --threads {config[kraken_threads]} \
            --output - \
            --report {output.report} \
            {params.paired} \
            {input.reads} \
            2> >(tee {log})
        """


rule braken:
    input:
        "kraken_results/{db_name}/reports/{sample}.txt",
        db= get_kraken_db_path,
    output:
        "kraken_results/{db_name}/braken_estimation/{sample}.txt"
    params:
        readlength=50,
        level= 'S1',
        threshold =0 # number of reads required PRIOR to abundance estimation to perform reestimation (default: 0)
    log:
        "logs/braken/{db_name}/{sample}.log"
    benchmark:
        "logs/benchmark/braken/{db_name}/{sample}.tsv"
    conda:
        "../envs/kraken.yaml"
    threads:
        1
    resources:
        time= config['classify_time']
    shell:
        "bracken "
        " -d {input.db} "
        " -i {input[0]} "
        " -o {output} "
        #" -w {output.report} "
        " -r {params.readlength} "
        " -l {params.level} "
        " -t {params.threshold} "
        " 2> >(tee {log}) "


rule combine_braken:
    input:
        expand("kraken_results/{{db_name}}/braken_estimation/{sample}.txt",
               sample = get_all_from_sampletable()
               )
    output:
        touch("classify_{db_name}")

# Usage: bracken -d MY_DB -i INPUT -o OUTPUT -w OUTREPORT -r READ_LEN -l LEVEL -t THRESHOLD
#   MY_DB          location of Kraken database
#   INPUT          Kraken REPORT file to use for abundance estimation
#   OUTPUT         file name for Bracken default output
#   OUTREPORT      New Kraken REPORT output file with Bracken read estimates
#   READ_LEN       read length to get all classifications for (default: 100)
#   LEVEL          level to estimate abundance at [options: D,P,C,O,F,G,S] (default: S)
#   THRESHOLD      number of reads required PRIOR to abundance estimation to perform reestimation (default: 0)





# kraken2 --db kraken_db --report ERP002061_fastq/ERR210758.report ERP002061_fastq/ERR210758.fq.gz --output - --threads


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
