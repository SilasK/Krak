include: "workflow_scripts.smk"
include: "sample_table.smk"


## define classify_db if not specified

if config['classify_db'] == 'default':
    available_kraken_dbs= list(config['kraken_db'].keys())
    if len(available_kraken_dbs) ==0:
        logger.critical("You didn't Specify any kraken db. "
                        "Specify the name and path to a kraken_db in the config file under 'kraken_db'."
                        )

    config['classify_db'] = available_kraken_dbs[0]
    if len(available_kraken_dbs) >1:
        logger.info(f"Use '{config['classify_db']}' as kraken_db. "
                    "If you want to use another one specify the name under 'classify_db' "
                    )


rule all:
    input:
        expand("kraken_results/counts_{level}_{db_name}.tsv",
               level=config['classify_level'], db_name=config['classify_db']
               )



checkpoint estimate_readlength:
    input:
        reads=get_quality_controlled_reads , # returns paired end or not
    output:
        "readstats/readlengths/{sample}.tsv"
    threads:
        1
    conda:
        "../envs/bbmap.yaml"
    log:
        "log/readlength/{sample}.log"
    params:
        inputs = lambda wc,input: io_params_for_tadpole(input.reads)
    shell:
        "readlength.sh {params.inputs} out={output[0]} "
        " max=1000  2> {log}"





rule kraken:
    input:
        reads=get_quality_controlled_reads , # returns paired end or not
        db= get_kraken_db_path,
        db_files = get_kraken_db_files
    output:
        #kraken="kraken_results/{db_name}/kraken_results/{sample}.kraken",
        report= "kraken_results/{db_name}/reports/{sample}.txt"
    log:
        "log/kraken/{db_name}/{sample}.log"
    benchmark:
        "log/benchmark/kraken/{db_name}/samples/{sample}.tsv"
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


def get_braken_dbfile(wildcards):
    """
        Braken uses different databases for different readlengths.
        The readlength is given or infered from the input reads.
        The database with the most similar readlength is choosen.


    """

    import numpy as np
    readlength_mode= config.get('readlength','infer_all')

    if type(readlength_mode)  == int:

        sample_readlength = readlength_mode

    elif not (type(readlength_mode) == str \
              and (readlength_mode=='infer_all' \
                   or readlength_mode=='infer_one'
                   )
              ) :

        raise Exception(f"Didn't understand 'readlength' in config file. "
                        "Specify an number, 'infer_one' or 'infer_all' \n"
                        "got: {readlength_mode}"
                        )
    else: # Infer readlength

        if readlength_mode == 'infer_one':
            # take first smple
            sample_for_inference = get_all_from_sampletable()[0]
        elif readlength_mode == 'infer_all':
            sample_for_inference = wildcards.sample



        # get read length file either from atlas otherwise generate it by calling checkpoint
        atlas_readlength_file= "{sample}/sequence_quality_control/read_stats/QC_read_length_hist.txt".format(sample = sample_for_inference)

        if os.path.exists(atlas_readlength_file):
            read_length_file = atlas_readlength_file
        else:
            # checkpoint
            read_length_file = checkpoints.estimate_readlength.get( sample=sample_for_inference
                                                                   ).output[0]



        # parse file and get median read_length
        from utils.parsers_bbmap import parse_comments
        sample_readlength = parse_comments(read_length_file)['Median']
        sample_readlength = int(sample_readlength)


    # see what brakendb are available
    kraken_db_path = get_kraken_db_path(wildcards)
    brakendb_path_template = f"{kraken_db_path}/database{{readlength}}mers.kraken"
    avalable_braken_sets = glob_wildcards(brakendb_path_template).readlength
    if len(avalable_braken_sets)==0:
        raise Exception("Don't find braken dbs searched for: \n"
                        f"{kraken_db_path}/database*mers.kraken"
                        )


    # calculate closest braken file
    avalable_braken_sets = np.array(avalable_braken_sets,dtype=int)
    diff =  np.abs(avalable_braken_sets -sample_readlength)
    optimal_readlength =  avalable_braken_sets[np.argmin(diff)]

    # Warn if not optimal choice
    if min(diff) > 30:
        raise Exception(f"Dont't find a braken db that matches well to readlength of sample {wildcards.sample}\n"
                    f"db_path: {kraken_db_path} \n"
                    f"Available dbs for readlength: {avalable_braken_sets}\n"
                    f"readlength of sample {wildcards.sample}: {sample_readlength}\n"
                    )


    # format braken db file
    braken_db = brakendb_path_template.format(
        readlength=optimal_readlength
        )

    return braken_db

def parse_readlenth_from_braken_dbfile(wildcards, input):
    """
        parse readlength from database{readlength}mers.kraken
    """

    braken_db_file = os.path.basename(input.braken_db)

    read_length = braken_db_file.replace('database','').replace('mers.kraken','')
    return read_length



braken_level_mapping = {
    'species' : 'S',
    'genus' :   'G',
    'subsp': 'S1',
    'family': 'F',
}

wildcard_constraints:
    level="(family|genus|species|subsp)"

rule braken:
    input:
        "kraken_results/{db_name}/reports/{sample}.txt",
        db= get_kraken_db_path,
        braken_db = get_braken_dbfile
    output:
        "kraken_results/{db_name}/braken_estimation/{level}/{sample}.txt"
    params:
        readlength= parse_readlenth_from_braken_dbfile,
        level = lambda wildcards: braken_level_mapping[wildcards.level],
        threshold =0 # number of reads required PRIOR to abundance estimation to perform reestimation (default: 0)
    log:
        "log/braken/{db_name}/{sample}_{level}.log"
    benchmark:
        "log/benchmark/braken/{db_name}/{sample}_{level}.tsv"
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
        " &> >(tee {log}) "





localrules: combine_braken
rule combine_braken:
    input:
        expand("kraken_results/{{db_name}}/braken_estimation/{{level}}/{sample}.txt",
               sample = get_all_from_sampletable()
               )
    output:
        "kraken_results/counts_{level}_{db_name}.tsv"
    log:
        "log/braken/{db_name}/combine_braken_{level}.txt"
    script:
        "../scripts/combine_braken_reports.py"

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
