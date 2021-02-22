#! /usr/bin/env python3


with open(snakemake.log[0],"w") as log:
    sys.stderr= log
    sys.stdout= log

    braken_report_files = snakemake.input
    output_table = snakemake.output[0]

    import os
    import pandas as pd



    Combined_counts = {}

    # read all braken files and store species - counts in a dictonary
    for bf in braken_report_files:
        B = pd.read_table(bf,index_col=0)
        sample_name= os.path.splitext(os.path.basename(bf))[0]

        print(f"Read braken file for {sample_name}")

        Combined_counts[sample_name] = B.new_est_reads



    Combined_counts = pd.concat(Combined_counts,axis=1,sort=True,verify_integrity=True)
    Combined_counts= Combined_counts.fillna(0).astype(int)
    Combined_counts.to_csv(output_table,sep='\t')
