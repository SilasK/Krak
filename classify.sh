#!/usr/bin/env bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

snakefile="$SCRIPT_DIR/workflow/classify.smk"

snakemake  -s "$snakefile" \
--use-conda \
-j30 --profile cluster --scheduler greedy $@
#
