import os

workflow_folder= os.path.dirname(workflow.snakefile)
# use default config
configfile: os.path.join(workflow_folder,'..','config.yaml')
sys.path.append(os.path.join(workflow_folder,'..',"scripts"))

kraken_db_files=["hash.k2d", "opts.k2d","taxo.k2d"]


def get_kraken_db_path(wildcards):
    """
        get the path from config['kraken_db'][wildcards.db_name]
        and verifies if all the files for a correct kraken2 db are there
    """

    db_name= wildcards.db_name
    assert 'kraken_db' in config, 'Expect a directory named "kraken_db" in the config file'
    assert db_name in config['kraken_db'], f'The name "{db_name}" is not in the config file under "kraken_db"'

    kraken_db_folder = config['kraken_db'][db_name]

    if not os.path.exists(kraken_db_folder):
        raise IOError(f"{kraken_db_folder} doesn't exist")

    if not all( os.path.exists(os.path.join(kraken_db_folder,file)) for file in kraken_db_files):
        raise IOError(f"Expect {kraken_db_files} in {kraken_db_folder}")


    return kraken_db_folder


def get_kraken_db_files(wildcards):
    "depending on wildcard 'db_name' "
    return expand("{path}/{file}",
               path=get_kraken_db_path(wildcards),
               file=kraken_db_files
               )

def calculate_kraken_memory(wildcards, overhead=7000):
    "Calculate db size of kraken db. in MB "
    "depending on wildcard 'db_name' "

    db_size_bytes = sum( os.path.getsize(f) for f in get_kraken_db_files(wildcards) )

    return db_size_bytes // 1024**2 +1 + overhead
