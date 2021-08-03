

kraken_db_urls = {
                  'CMGM': "https://ezmeta.unige.ch/CMGM/v1/CMGM_v1_kraken2_db.tar.gz",
                  'UHGG': "https://ezmeta.unige.ch/CMGM/v1/UHGG_v1_kraken2_db.tar.gz",
                  }


wildcard_constraints:
    download_db = "("+ '|'.join(kraken_db_urls.keys()) +")"

localrules: download_kraken_db


rule download_kraken_db:
    output:
        temp("kraken_db/{download_db}.tar.gz"),
    params:
        url= lambda wc: kraken_db[wc.db]
    log:
        "log/download/{download_db}.log"
    shell:
        "wget -O {output} {params.url} 2> {log}; "

rule extract_kraken_db:
    input:
        "kraken_db/{download_db}.tar.gz",
    output:
        "kraken_db/{download_db}"
    log:
        "log/download/{download_db}.log"
    shell:
        "tar -xzf -C {output} --strip-components 1 {input} 2>> {log}; "
