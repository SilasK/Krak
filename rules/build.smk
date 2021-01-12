
localrules: flextaxd_createdb, build

rule build:
    input:
        expand("{folder}/{file}",
               folder=config['build_db_name'],
               file= kraken_db_files),
        expand("{db_name}/braken/{readlength}_done",
                 db_name= config['build_db_name'],
                 readlength=[50,100,150]
                 )


rule flextaxd_createdb:
    input:
        config['taxonomy']
    output:
        db="build/flextaxd/flextaxd.ftd",
        nodes= "build/flextaxd/nodes.dmp",
        names= "build/flextaxd/names.dmp"
    params:
        out_path= "build/flextaxd/"
    conda:
        "../envs/kraken.yaml"
    log:
        "log/build/flextaxd_create_db.log"
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
        db="build/flextaxd/flextaxd.ftd",
        nodes= "build/flextaxd/nodes.dmp",
        names= "build/flextaxd/names.dmp",
        genome_folder = config['genome_folder']
    output:
        expand("{{db_name}}/{file}", file=kraken_db_files)
    params:
        taxonomy= "build/flextaxd",
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
        "-o {params.taxonomy} "
        " --genomes_path {input.genome_folder} "
        "-p {threads} "
        " --create_db --dbprogram kraken2 "
        "--log log/kraken --verbose --debug &> {log}"


#bracken https://ccb.jhu.edu/software/bracken/index.shtml?t=manual






wildcard_constraints:
    readlength="\d+"

rule build_braken_db:
    input:
        rules.build_kraken_db.output
    output:
        touch("{db_name}/braken/{readlength}_done")
    threads:
        config['braken_threads']
    conda:
        "../envs/kraken.yaml"
    log:
        "log/build/braken_db/{db_name}_{readlength}.log"
    benchmark:
        "log/benchmark/build/braken_db/{db_name}_{readlength}.tsv"
    shell:
        "bracken-build "
        " -t {threads} "
        " -d {wildcards.db_name} "
        " -l {wildcards.readlength}"
