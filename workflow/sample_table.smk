SAMPLEFILE_HEADERS=[]

# gloabal variable
SAMPLE_TABLE = None

def validate_sample_table(SampleTable):

    Expected_Headers = SAMPLEFILE_HEADERS
    for h in Expected_Headers:
        if not (h in SampleTable.columns):
         logging.error(f"expect '{h}' to be found in samples.tsv")
         exit(1)

    if not SampleTable.index.is_unique:
        duplicated_samples=', '.join(D.index.duplicated())
        logging.error( f"Expect Samples to be unique. Found {duplicated_samples} more than once")
        exit(1)

    if SampleTable.index.isnull().any():
        logging.error( "Some samples names (index) of the sample table are empty. Check if there is no empty line at the end")
        exit(1)

def get_sample_table_file():

    sample_table_file = config.get('sample_table','samples.tsv')

    if not os.path.exists(sample_table_file):
        raise IOError(f'Sample Table "{sample_table_file}" does not exists.'
                      ' Specify a correct path in the config files under'
                      ' "sample_table".' )

    return sample_table_file


def get_sample_table():
    """ Load sample if not already exists
    """

    global SAMPLE_TABLE

    if SAMPLE_TABLE is None:

        import pandas as pd
        SAMPLE_TABLE = pd.read_csv(get_sample_table_file(), index_col=0,sep='\t')
        validate_sample_table(SAMPLE_TABLE)

    return SAMPLE_TABLE

class SampleTableError(IOError):
    """
        Exception with SampleTable
    """
    def __init__(self, message):

        global SAMPLE_TABLE

        if SAMPLE_TABLE is None:
            raise Exception("Sample Table is not loaded.")


        sample_table_file = get_sample_table_file()
        message += '\nFrom Sample Table '+sample_table_file

        super(SampleTableError, self).__init__(message)




def get_all_from_sampletable(column='index'):
    "get all unique values from a sample table, default index"

    SampleTable = get_sample_table()

    if column =='index':
        return SampleTable.index.values
    else:

        if column not in SampleTable.columns:
            raise SampleTableError(f'column "{column}" not found.')

        if SampleTable[column].isnull().any():
            raise SampleTableError(f'Some elements of the column "{column}" are empty.')

        return SampleTable[column].unique()








def get_files_from_SampleTable(sample,Headers):
    """
        Function that gets some filenames form the SampleTable for a given sample and Headers.
        It checks various possibilities for errors and throws either a
        FileNotInSampleTableError or a IOError, when something went really wrong.
    """


    # load global variable SampleTable if not exists
    SampleTable = get_sample_table()

    # convert headers to list also if only one is given
    if type(Headers) == str:
        Headers= [Headers]

    # check if sample and Headers are in Sample Table
    if sample not in SampleTable.index:
        raise SampleTableError(f"Sample name {sample} not found.")

    Headers_not_in_sample_table = set(Headers) - set(SampleTable.columns)
    if len(Headers_not_in_sample_table) > 0:
        raise SampleTableError(f"The folowing headers were not found: {Headers_not_in_sample_table} ")




    files= SampleTable.loc[sample,Headers]

    if files.isnull().any():
        raise SampleTableError("Some files are empty in SampleTable.\n"
                               f"Sample: {sample}\n"
                               f"Header: {Header}\n"
                               f"Files: {list(files)}"
                               )

    return list(files)



def get_quality_controlled_reads(wildcards):

    if config.get('paired_reads',True):
        fractions = ['R1','R2']
    else:
        fractions = ['se']

    QC_Headers=["Reads_QC_"+f for f in fractions]

    return get_files_from_SampleTable(wildcards.sample,QC_Headers)



## BB MAp

def io_params_for_tadpole(io,key='in'):
    """This function generates the input flag needed for bbwrap/tadpole for all cases
    possible for get_quality_controlled_reads.

    params:
        io  input or output element from snakemake
        key 'in' or 'out'

        if io contains attributes:
            se -> in={se}
            R1,R2,se -> in1={R1},se in2={R2}
            R1,R2 -> in1={R1} in2={R2}

    """
    N= len(io)
    if N==1:
        flag = f"{key}1={io[0]}"
    elif N==2:
        flag= f"{key}1={io[0]} {key}2={io[1]}"
    elif N==3:
        flag= f"{key}1={io[0]},{io[2]} {key}2={io[1]}"
    else:
        logger.critical(("File input/output expectation is one of: "
                         "1 file = single-end/ interleaved paired-end "
                         "2 files = R1,R2, or"
                         "3 files = R1,R2,se"
                         "got: {n} files:\n{}").format('\n'.join(io),
                                                       n=len(io)))
        sys.exit(1)
    return flag
