#! /usr/bin/env python3


import sys,os
import logging, traceback
logging.basicConfig(filename=snakemake.log[0],
                    level=logging.INFO,
                    format='%(asctime)s %(message)s',
                    datefmt='%Y-%m-%d %H:%M:%S',
                    )
def handle_exception(exc_type, exc_value, exc_traceback):
    if issubclass(exc_type, KeyboardInterrupt):
        sys.__excepthook__(exc_type, exc_value, exc_traceback)
        return

    logger.error(''.join(["Uncaught exception: ",
                         *traceback.format_exception(exc_type, exc_value, exc_traceback)
                         ])
                 )
# Install exception handler
sys.excepthook = handle_exception


import pandas as pd


##snakemake I/O
braken_report_files = snakemake.input.braken
output_counts_table = snakemake.output[0]
mapped_reads_name = snakemake.wildcards.db_name+'_'+snakemake.wildcards.level
stats_table_file= snakemake.params.mapping_table
kraken_report_files = snakemake.input.kraken

## combine braken files
Combined_counts = {}

# read all braken files and store species - counts in a dictonary
for bf in braken_report_files:
    B = pd.read_table(bf,index_col=0)
    sample_name= os.path.splitext(os.path.basename(bf))[0]


    Combined_counts[sample_name] = B.new_est_reads


# save combined counts
Combined_counts = pd.concat(Combined_counts,axis=1,sort=True,verify_integrity=True)
Combined_counts= Combined_counts.fillna(0).astype(int).T
Combined_counts.to_csv(output_counts_table,sep='\t')



### save mapped reads to file

# parse kraken_tables to get total reads
if os.path.exists(stats_table_file):
    logger.info('Load table with total counts')
    stats_table= pd.read_table(stats_table_file,index_col=0)
else:
    logger.warning('Parse kraken files to estimate total reads')
    
    # parse all kraken_files to calculate total reads
    total_reads={}
    for kf in kraken_report_files:
        sample_name= os.path.splitext(os.path.basename(kf))[0]

        total_reads[sample_name] = pd.read_table(kf,usecols=[2],header=None,squeeze=True,dtype=int).sum()

    stats_table = pd.DataFrame(pd.Series(total_reads , name='Total_reads'))


# sum counts table to get mapped reads
mapped_reads= Combined_counts.sum(1)
stats_table[mapped_reads_name]= mapped_reads/ stats_table.Total_reads

stats_table.to_csv(stats_table_file, sep='\t',float_format='%.4f')
