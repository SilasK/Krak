#!/usr/bin/env bash



snakemake  -s /home/kiesers/Kraken/Snakefile \
--use-conda --conda-prefix /home/kiesers/scratch/Atlas/databases/conda_envs/ \
--default-resources time=1 mem=5 -j3  $@
# --profile cluster
