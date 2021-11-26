# MLSS.pl
Multilocus Sequence Search

Written by James Bray (james.bray@zoo.ox.ac.uk)

Copyright (C) 2021 University of Oxford

Sections of README document
1) Overview
2) Installation
3) Program Usage
4) File Format Information
5) Technical Notes

## SECTION 1: Overview
----------------------

MLSS: Multilocus Sequence Search

Search bacterial genome sequences to identify DNA regions corresponding 
with genes defined by multilocus sequence typing (MLST, rMLST etc) using a 
library of sequence typing alleles. Calculate nucleotide identity (NI) 
values between the query genome and a library of allelic profiles 
(default: local identity calculation).

This program can be used for bacterial species identification when used
in conjunction with Ribosomal MLST (rMLST).

## SECTION 2: Installation
--------------------------

### 2.1 Program Dependencies (External):

#### 2.1.1 METACPAN: Log::Log4perl

https://metacpan.org/pod/Log::Log4perl
This module is used by this program for logging purposes.
Install from METACPAN according to the instructions found on the METACPAN site.

#### 2.1.2 Requires BLAST executable: blastn
Download the latest BLAST+ software from NCBI BLAST website (https://blast.ncbi.nlm.nih.gov).

Program uses environment variable BLAST_BIN_PATH to find the blast bin directory
Set this in your shell environment prior to running.
```
export BLAST_BIN_PATH=<path_to_your_blast_bin_directory>
```
e.g. /usr/bin

### 2.2 Module Requirements (Internal):

Modules included with this distribution:
```
DefaultLoggerConfig.pm
GetListFromFile.pm
NumericalChecks.pm
ProfileTableReader.pm
Profile.pm
Allele.pm
PairwiseEntry.pm
ScanThresholdsReader.pm
ScanThresholdsEntry.pm
ScanEntry.pm
ScanWriter.pm
JTableReader.pm
JTable.pm
```
These modules need to be placed inside a directory called 'lib'
in the directory where the MLSS.pl program is located.

### 2.3 Input File and Directory Requirements:

See below for detailed file format information.
```
- A list of genomic sequence filenames
- Name of the directory where the genomic sequence files are stored (warehouse directory)
- A single FASTA file of allele sequences.
- A single PROFILE file of profile definitions (tab separated text file)
       One row of the table contains the 'profile' data for that entity.
- (Optional) A single ALLELE LENGTHS file. Allele length information for all entries in FASTA file
       Not supplied on the command line.
       Name must be FASTA_FILE.lengths and placed in the same directory as the FASTA file
       Mirroring the BLAST index file naming convention
- (Optional) A single THRESHOLDS file. Profile identity thresholds for all profile entries in PROFILE file
       Used for calculating traffic light colour for reporting the significance of each reported 
       nucleotide identity.
```

## SECTION 3: Program Usage
---------------------------

### 3.1 Required Options:
```
-in       <FILE> filename of input list of genome/contig files
-dir      <DIRECTORY> Genome/contig directory
-db       <FILE> Root filename of BLAST indexed sequence database
-profiles <FILE> Profiles filename
-out      <FILE> LOG FILE (Error file: OutputFilename.error)

-field=id   ] select one of these profile identifier field options
-field=rST  ] 
```

### 3.2 Typical Usage:

```
MLSS.pl \
-in LIST_ContigsFiles.txt \
-dir ./contigs \
-db SEQS_Alleles.fa  \
-profiles PROFILES.txt \
-field=id \
-out LOGFILE.txt
```

### 3.3 Standard Options:
```
-h         - print usage instructions
-v         - print program version
```
### 3.4 Advanced Options:
```
--delete   - Delete individual BLAST files [default]
--nodelete - Do not delete BLAST files

--seqid_collect [NUMBER] Minimum sequence identity (%) used by BLAST to collect matches (Default: 50)
--evalue_collect [NUMBER] Minimum E-value used by BLAST to collect matches (Default: 10)

--max_threads_per_job [INTEGER] Maximum CPU threads BLAST uses per job/search (Default: 1)

--seqid_cutoff [NUMBER] Minimum sequence identity (%) of a collected match to 
               include in identity calculation (Default: 50)
--overlap_cutoff [NUMBER] Minimum match overlap (%) of a collected match to 
               include in identity calculation (Default: 50)

--jobs [INTEGER] number of BLAST jobs to run in parallel (Default: 1)
--loci <FILE> List of loci to extract from profile table
--limit [INTEGER] limit number of lines in each results files (Default: 0 = no limit)

--first [INTEGER]  first entry in input list of query sequence files to process
--last [INTEGER]  last entry in input list of query sequence files to process

--method=global ] Calculate nucleotide identity globally
--method=local  ] Calculate nucleotide identity locally (Default: local)
                  (only count overlapping regions of profile alleles)

--task=blastn    ] BLASTN '-task [OPTION]' (Default: blastn)
--task=megablast ]
```
## SECTION 4: File Format Information
-------------------------------------

### 4.1 Input File Format: List of Genome/Contigs Files
```
ISOLATE_1_A0_contigs.fa
ISOLATE_2_A0_contigs.fa
```
	
### 4.2 Input File Format: Genome Files

Sequence format = FASTA

### 4.3 Input File Format: Allele Sequence File

Sequence format = FASTA

This file must be indexed using makeblastdb.
COMMAND: 
```
makeblastdb -in FASTA_FILE.fa -dbtype nucl
```

Must use the same BLAST version of makeblastdb as blastn
Program checks for 3 blast index files (ending  in .nin, .nsq, .nhr) 
to ensure that makeblastdb has been run.

### 4.4 Input File Format: Lengths File (Optional)

Optional file - NOT supplied on the command line.
Name must be FASTA_FILENAME.lengths and placed in the same directory as 
the allele sequence FASTA file (mirroring the BLAST index file naming convention).

Two column format (tab separated)
```
Column 1: Allele identifier
Column 2: Allele length
```

Example:
```
BACT000001_3577	1674
BACT000002_86	726
BACT000003_63	699
```

### 4.5 Input File Format: Profile Table

Header line to contain (tab separated):
Minimally requires 'id' OR 'rST' and locus names. Cannot contain duplicate header values.
Example (truncated after two loci):
```
id	isolate	species	BACT000001	BACT000002
```
Data lines to contain profile id and allele identifiers:
Example (truncated after two loci):
```
23	KCTC 2190	Klebsiella aerogenes	3916	2949
```

### 4.6 Input File Format: Thresholds File

Seven columns (tab separated):
```
Column 1: Profile Identifier (e.g. ISOLATE_1 or RST_1)
Column 2: Threshold A (range 0-100)
Column 3: Threshold A fraction (number/number, default: 0/0)
Column 4: Threshold B (range 0-100)
Column 5: Threshold B fraction (number/number, default: 0/0)
Column 6: Species (string)
Column 7: Comments (default: N/A)
```

If the threshold fraction is present from observed data (ie. is not the default value) 
the threshold is internally re-calculated from the fraction to avoid using a number 
that has been rounded up/down in the traffic light colour calculation.

Example line (from observed data):
```
ISOLATE_23	98.84958	20622/20862	98.17371	20481/20862	Klebsiella aerogenes	N/A
```
Example line (generic values):
```
ISOLATE_8556	99.95000	0/0	99.75000	0/0	Klebsiella africana	N/A
```
Traffic Light System (of Identity Significance):
```
Threshold A is the lowest observed value (%) of a same species match for this profile.
Threshold B is the highest observed value (%) of a different species match for this profile.
Identity values between 100% and threshold A (inclusive) are labelled as Green
Identity values below threshold A and above threshold B are labelled as Amber.
Identity values equal to or below threshold B are labelled as Red.
```
	
### 4.7 File Format: Loci File (optional)

Single column file of locus identifiers.
Overrides the internal list of 53 rMLST locus identifiers.
Identifiers must not contain spaces.

### 4.8 Output File Format: 

SCAN FILE FORMAT 2.1 (12 columns)
Tab separated format:
```
Column 1: Rank Number
Column 2: Contigs Filename
Column 3: Profile Name (string)
Column 4: Sequence Identity (%)
Column 5: Profile Species
Column 6: Traffic Light Colour
Column 7: Nucleotide Overlap (%)
Column 8: Matched Allele Count  / Profile Allele Count
Column 9: Number of Identical Matches / Profile Nucleotide Count
Column 10: Matched Nucleotide Count / Profile Nucleotide Count
Column 11: Total Blast Score
Column 12: Profile Numeric Identifier
```

Example:
```
1	ISOLATE_23_A0_contigs.fa	ISOLATE_23	100.00000	Klebsiella aerogenes	Green	100.00000	51/51	20862/20862	20862/20862	20862	23
2	ISOLATE_23_A0_contigs.fa	ISOLATE_331	98.14016	Klebsiella variicola	Red	99.99041	51/51	20474/20862	20860/20862	19687	331
3	ISOLATE_23_A0_contigs.fa	ISOLATE_3288	97.58412	Klebsiella quasivariicola	Red	99.98083	51/51	20358/20862	20858/20862	19340	3288
```
Output filename for each query:
Root of the input genome filename (before the dot) appended with '_RESULTS'.
Example: 'ISOLATE_23_A0_contigs.fa' produces a results file named 'ISOLATE_23_A0_contigs_RESULTS'

Output Error File:
Program reports missing BLAST output files to the error file


## SECTION 5: Technical Notes
--------------------------

### 5.1 PROGRAM STEPS:

STEP 1. Read input files and perform data sanity checks
```
A. list of input QUERY genomic sequence filenames
B. Read directory where these files are stored (WAREHOUSE)
C. ALLELE FASTA sequence library
D. PROFILE table file
E. (optional) ALLELE LENGTHS file
F. (optional) Profile THRESHOLDS file

Obtain additional information:
- If ALLELE LENGTHS not provided: read ALLELE FASTA file to obtain length information

Data sanity checks
- Check all input genomic sequences exist in the warehouse directory
- If ALLELE LENGTHS provided: check all allele sequences in ALLELE FASTA file are present 
- If THRESHOLDS file provided: check all profile identifiers in PROFILE file are present 
```
STEP 2. Scan QUERY sequence again ALLELE FASTA sequence library
      Results are output to a tabular format file.

STEP 3. Read tabular format file and extract the best match to each allele
      Best match is based on raw score value.
      Care is taken to account for allelic match results reported per searched contig.

STEP 4. Calculate the nucleotide identity (%) and percentage of overlap between genome and profile alleles

STEP 5. (optional) If THRESHOLDS file provided: calculate the traffic light colour for each profile match

STEP 6. Rank the PROFILE table entries by nucleotide identity (highest first) 
      Write one results file per input QUERY file

STEP 7. Repeat steps 2 to 6 for all input QUERY files


### 5.2 IDENTITY CALCULATIONS:

Calculate LOCAL Sequence Identity:
Identity (%) = 100 x ( total identical matches [A] / total of aligned allele lengths [B] )

Aligned allele length is calculated from the start and stop positions of the match 
(allele sequence) reported by BLAST. Total aligned allele length is the sum of all allele match lengths.

Calculate GLOBAL Sequence Identity:
Identity (%) = 100 x ( total identical matches [A] / total profile nucleotide count [C] )

Therefore if a profile allele is not matched at all, the length of this allele is counted
in the identity calculation.

Calculate Nucleotide Overlap:
Overlap (%) = 100 x ( total of aligned allele lengths [B] / total profile nucleotide length [C] )

### 5.3 ALLELE MATCH CRITERIA:

BLAST E-value collect and Sequence identity collect both need to be satisfied 
for the BLAST match to be accepted (defaults E-value=10, Sequence identity=50)
In addition, each allelic match must pass minimum overlap length and sequence identity 
criteria to be included in the nucleotide identity calculation (defaults: 50% overlap and 50% identity)

### 5.4 PROFILE TABLE SOURCE:

There are two sources of profiles: ISOLATE database or the SEQDEF database.
Profile entries generated from Isolate database file using 'id' field are prefixed: 'ISOLATE_'
Profile entries generated from Sequence Definition file using 'rST' field are prefixed: 'RST_'
and those using 'ST' field are prefixed: 'ST_'

If required the thresholds file profile identifiers must match the identifier generated internally
based on 'id' (ISOLATE_), 'rST' (RST_) or 'ST' (ST_)

### 5.5 TEMPORARY FILENAMES:

Program creates a '.lock' file for each QUERY file search to prevent any other 
instance of this program trying to write to the same results filename during the 
BLAST search and nucleotide identity calculation process.

This is removed when each job (per query input file) is completed. 
If the program has died/crashed during operation, there may be some of
these files left in the working directory.

Temporary BLAST tabular output files are created for each BLAST search:
Filename(s) is a concatenation of the query filename (root part) and the 
allele sequence library (root part) joined with an underscore and appended by '_BLAST'.
Two files are generated:
```
QUERY_AlleleFasta_BLAST.tmp (unsorted file)
QUERY_AlleleFasta_BLAST (sorted file)
```


