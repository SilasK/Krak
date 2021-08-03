#!/usr/bin/env python
import logging
import os
import sys
import pandas as pd
import numpy as np
from collections import defaultdict
import argparse


def infer_split_character(base_name):
    "Infer if fastq filename uses '_R1' '_1' to seperate filenames"

    if ("_R1" in base_name) or ("_R2" in base_name):
        return "_R"
    elif ("_1" in base_name) or ("_2" in base_name):
        return "_"
    else:
        logging.warning(
            f"Could't find '_R1'/'_R2' or '_1'/'_2' in your filename {base_name}. Assume you have single-end reads."
        )
        return None


def control_sample_name(sample_name):
    "Verify that sample doesn't contain bad characters"

    assert (
        sample_name != ""
    ), "Sample name is empty do you have some hidden files in your repo? check with ls -a"

    if sample_name[0] in "0123456789":
        sample_name = "S" + sample_name
        logging.warning(f"Sample starts with a number. prepend 'S' {sample_name}.")

    return sample_name.replace("-", "_").replace(" ", "_")


def add_sample_to_table(sample_dict, sample_id, header, fastq):
    "Add fastq path to sample table, check if already in table"

    if (sample_id in sample_dict) and (header in sample_dict[sample_id]):

        logging.error(
            f"Duplicate sample {sample_id} {header} was found after renaming;"
            f"\n Sample1: \n{sample_dict[sample_id]} \n"
            f"Sample2: {fastq}"
        )
        exit(1)
    else:
        sample_dict[sample_id][header] = fastq


def get_samples_from_fastq(path, split_character="infer"):
    """
    creates table sampleID R1 R2 with the absolute paths of fastq files in a given folder
    """
    samples = defaultdict(dict)

    for dir_name, sub_dirs, files in os.walk(os.path.abspath(path)):
        for fname in files:

            # only look at fastq files
            if ".fastq" in fname or ".fq" in fname:
                fq_path = os.path.join(dir_name, fname)
                base_name = fname.split(".fastq")[0].split(".fq")[0]

                if (split_character is not None) and (split_character == "infer"):
                    split_character = infer_split_character(base_name)

                if split_character is None:
                    # se reads
                    sample_id = control_sample_name(base_name)
                    add_sample_to_table(samples, sample_id, "R1", fq_path)

                else:
                    sample_id = control_sample_name(base_name.split(split_character)[0])
                    if (split_character + "2") in base_name:
                        add_sample_to_table(samples, sample_id, "R2", fq_path)
                    elif (split_character + "1") in base_name:

                        add_sample_to_table(samples, sample_id, "R1", fq_path)
                    else:

                        logging.error(
                            f"Did't find '{split_character}1' or  "
                            f"'{split_character}2' in fastq {sample_id} : {fq_path}"
                        )
                        exit(1)

    samples = pd.DataFrame(samples).T

    if samples.isnull().any().any():
        logging.error(f"Missing files:\n\n {samples}")
        exit(1)

    if samples.shape[0] == 0:
        logging.error(
            f"No files found in {path}\n"
            "I'm looking for files with .fq or .fastq extension. "
        )
        exit(1)

    return samples


def main(output_file='samples.tsv',**kws):

    if os.path.exists(output_file):
        logging.error(f"File {output_file} already exists.")
        exit(1)

    sample_table= get_samples_from_fastq(**kws)

    # rename columns
    columns = sample_table.columns  # R1 and R2 or only R1 , who knows

    if "R2" not in columns:
        assert len(columns) == 1, "expect columns to be only ['R1']"
        sample_table.columns = ["se"]


    sample_table.columns = ["Reads_QC_" + c for c in columns]

    sample_table.sort_index(inplace=True)


    sample_table.to_csv(output_file,sep='\t')


if __name__ == "__main__":


    p = argparse.ArgumentParser(description='Generate a sample table from fastq.gz files in a folder(structure) ')
    p.add_argument("path", help="Folder with fastq files. Folder can have subfolders.")
    p.add_argument("-o", "--output-file", default="samples.tsv" )
    p.add_argument( "--split-character", default="infer", help="For paired end files. The forward/reverse read file is usually indicateded either with '_R' or '_' e.g. sample1_R1.fastq.gz" )
    args = vars(p.parse_args())
    main(**args)
