
import os

snakemake_folder= os.path.dirname(workflow.snakefile)
# use default config
configfile: os.path.join(snakemake_folder,'config.yaml')
sys.path.append(os.path.join(snakemake_folder,"scripts"))

kraken_db_files=["hash.k2d", "opts.k2d","taxo.k2d"]

include: "rules/build.smk"
include: "rules/classify.smk"



def get_kraken_db_path(wildcards):
    """
        get the path from config['kraken_db'][wildcards.db_name]
        and verifies if all the files for a correct kraken2 db are there
    """

    key= wildcards.db_name
    assert 'kraken_db' in config, 'Expect a directory named "kraken_db" in the config file'
    assert db_name in config['kraken_db'], f'The name "{db_name}" is not in the config file under "krakendb"'

    kraken_db_folder = config['kraken_db'][key]

    if not os.path.exists(kraken_db_folder):
        raise IOError(f"{kraken_db_folder} doesn't exist")

    if not all( os.path.exists(os.path.join(kraken_db_folder,file)) for file in kraken_db_files):
        raise IOError(f"Expect {kraken_db_files} in {kraken_db_folder}")


    return kraken_db_folder

# import os
# import re
# import sys
# from glob import glob
# from snakemake.utils import report
# import warnings
