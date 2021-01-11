#!/usr/bin/env bash



snakemake  -s /home/kiesers/Popularity/Snakefile \
--use-conda --default-resources time=1 mem=5 -j3 --profile cluster $@
