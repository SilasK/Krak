include: "sample_table.smk"







rule kraken_single:
    input:
        reads=lambda wc: get_files_from_sampleTable(wc.sample,['Reads_QC_se']),
        db= get_kraken_db_path
    output:
        kraken="kraken_results/{db_name}/kraken_results/{sample}_se.kraken",
        report="kraken_results/{db_name}/kraken_reports/{sample}_se.txt"
    log:
        "logs/run/{db_name}/{sample}_se.log"
    benchmark:
        "logs/benchmark/run/{db_name}/{sample}_se.log"
    conda:
        "../envs/kraken.yaml"
    params:
        extra: config.get("kraken_run_extra","")
    resources:
        mem=config['kraken_mem'],
        time= config['kraken_time']
    threads:  config['kraken_threads']
    shell:
        """
            kraken2 \
            --db {input.db} \
            {params.extra} \
            --threads {threads} \
            --output {output.kraken} \
            --report {output.report} \
            {input.reads} \
            2> >(tee {log})
        """

rule kraken_paired:
    input:
        R1=lambda wc: get_files_from_sampleTable(wc.sample,['Reads_QC_R1']),
        R2=lambda wc: get_files_from_sampleTable(wc.sample,['Reads_QC_R2']),
        db= get_kraken_db_path
    output:
        kraken="kraken_results/{db_name}/kraken_results/{sample}_pe.kraken",
        report="kraken_results/{db_name}/kraken_reports/{sample}_pe.txt"
    log:
        "logs/run/{db_name}/{sample}_pe.log"
    benchmark:
        "logs/benchmark/run/{db_name}/{sample}_pe.log"
    conda:
        "../envs/kraken.yaml"
    params:
        extra: config.get("kraken_run_extra","")
    resources:
        mem=config['kraken_mem'],
        time= config['kraken_time']
    threads:  config['kraken_threads']
    shell:
        """
            kraken2 \
            --db {input.db} \
            {params.extra} \
            --threads {threads} \
            --output {output.kraken} \
            --report {output.report} \
            --paired \
            {input.R1} {input.R2} \
            2> >(tee {log})
        """









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
