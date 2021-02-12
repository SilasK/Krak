
localrules: flextaxd_createdb, build

rule build:
    input:
        expand("{folder}/{file}",
               folder=config['build_db_name'],
               file= kraken_db_files),
        expand("{db_name}/database{readlength}mers.kraken",
                 db_name= config['build_db_name'],
                 readlength=[50,100,150]
                 )


rule flextaxd_createdb:
    input:
        config['taxonomy']
    output:
        db="{db_name}/flextaxd/flextaxd.ftd",
        nodes= "{db_name}/flextaxd/nodes.dmp",
        names= "{db_name}/flextaxd/names.dmp"
    params:
        out_path= lambda wc,output: os.path.dirname(output[0])
    conda:
        "../envs/kraken.yaml"
    log:
        "log/build/flextaxd/{db_name}.log"
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
        "--logs log/flextaxd/  2>> {log}"



rule build_kraken_db:
    input:
        db="{db_name}/flextaxd/flextaxd.ftd",
        nodes= "{db_name}/flextaxd/nodes.dmp",
        names= "{db_name}/flextaxd/names.dmp",
        genome_folder = config['genome_folder']
    output:
        krakendb=expand("{{db_name}}/{file}", file=kraken_db_files),
        seqid2taxid= "{db_name}/seqid2taxid.map.gz"
    params:
        taxonomy= lambda wc,input: os.path.dirname(input.db),
        kraken_path= lambda wc: os.path.abspath(wc.db_name)
    conda:
        "../envs/kraken.yaml"
    threads:
        config['kraken_threads']
    resources:
        mem=config['kraken_mem'],
        time=config['build_time']
    benchmark:
        "log/benchmark/build/build_kraken_db/{db_name}.tsv"
    log:
        "log/build/build_kraken_db/{db_name}.log"
    shell:
        "flextaxd-create "
        "--db_name {params.kraken_path} "
        "--database {input.db} "
        "--keep " #keep intermediary folder to create braken db
        "-o {params.taxonomy} "
        " --genomes_path {input.genome_folder} "
        "-p {threads} "
        " --create_db --dbprogram kraken2 "
        "--log log/kraken --verbose --debug &> {log}"


#bracken https://ccb.jhu.edu/software/bracken/index.shtml?t=manual


localrules: unzip_seqmap
rule unzip_seqmap:
    input:
        "{db_name}/seqid2taxid.map.gz"
    output:
        temp("{db_name}/seqid2taxid.map")
    shell:
        "gunzip -c {input} > {output}"


wildcard_constraints:
    readlength="\d+"

rule build_bracken_db:
    input:
        rules.build_kraken_db.output.krakendb,
        "{db_name}/seqid2taxid.map"
    output:
        "{db_name}/database{readlength}mers.kraken",
        "{db_name}/database{readlength}mers.kmer_distrib"
    threads:
        config['braken_threads']
    resources:
        mem=config['braken_mem'],
        time=config['build_time']
    conda:
        "../envs/kraken.yaml"
    log:
        "log/build/bracken_db/{db_name}_{readlength}.log"
    benchmark:
        "log/benchmark/build/bracken_db/{db_name}_{readlength}.tsv"
    shell:
        "bracken-build "
        " -t {threads} "
        " -d {wildcards.db_name} "
        " -l {wildcards.readlength}"
        " &> {log}"
