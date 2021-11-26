
# TUTORIAL.md

James Bray

Here is a short tutorial to guide you through the process of running MLSS.pl
in conjunction with a library of rMLST profiles representing 17 *Klebsiella/Raoultella* type strains.

This example uses a genome downloaded from the NCBI Assembly database ((https://www.ncbi.nlm.nih.gov/assembly Genbank assembly accession: GCA_000534255.1) annotated as *Klebsiella aerogenes* (March 2021). 

The following files should be present in two directories.

```
example_data/
DATASET_KlebsiellaDB_17TypeStrains.txt
THRESHOLDS_KlebsiellaDB_17TypeStrains_Original.txt
SEQS_Alleles_KlebsiellaDB_17TypeStrains.fa
SEQS_Alleles_KlebsiellaDB_17TypeStrains.fa.lengths

example_genomes/
GCA_000534255.1_Ente_aero_UCI_27_V1_genomic.fna

```
# Set shell variables

```
setenv BLAST_BIN_PATH [path_to_your_blast_bin_directory]
setenv PERL_DIR  [path_to_your_perl_directory] e.g. /home/<username>/perl
```

This example was run using BLAST executables from NCBI for ncbi-blast-2.12.0+.
If you do not have BLAST installed, download and install the latest version from the NCBI website (https://blast.ncbi.nlm.nih.gov).

# Create BLAST index files
```
cd $PERL_DIR/example_data
$BLAST_BIN_PATH/makeblastdb -in SEQS_Alleles_KlebsiellaDB_17TypeStrains.fa -dbtype nucl
```


# Command to run MLSS.pl

1. Create a directory to run MLSS.pl scans
(usually somewhere separate from where the perl code is stored)

2. Create a list of input filenames (e.g using 'echo' command)

```
mkdir scan
cd scan

echo GCA_000534255.1_Ente_aero_UCI_27_V1_genomic.fna > LIST_InputFilenames
```

Command:
```
perl $PERL_DIR/MLSS.pl \
-in LIST_InputFilenames \
-dir $PERL_DIR/example_genomes  \
-profiles $PERL_DIR/example_data/DATASET_KlebsiellaDB_17TypeStrains.txt \
-db $PERL_DIR/example_data/SEQS_Alleles_KlebsiellaDB_17TypeStrains.fa \
-field=id \
--thresholds $PERL_DIR/example_data/THRESHOLDS_KlebsiellaDB_17TypeStrains_Original.txt \
-out LOGFILE
```

This example contains the rMLST profiles for 17 type strain genomes from the *Klebsiella* and *Raoultella* genera
identified in the NCBI Assembly database in March 2021. The thresholds file was created from an analysis of more than 10,000 *Klebsiella/Raoultella* genomes.


| Profile Identifier | NCBI assembly accession | Isolate Name | Isolate Species |
| --- | --- | --- | --- |
| ISOLATE_23 | GCA_000215745.1 | KCTC 2190 | *Klebsiella aerogenes* |
| ISOLATE_8556 | GCA_900978845.1 | SB5857 | *Klebsiella africana* |
| ISOLATE_2990 | GCA_900200035.1 | 06D021 | *Klebsiella grimontii* |
| ISOLATE_8579 | GCA_003261575.2 | WCHKl090001 | *Klebsiella huaxiensis* |
| ISOLATE_9164 | GCA_005860775.1 | TOUT106 | *Klebsiella indica* |
| ISOLATE_4277 | GCA_002925905.1 | DSM 25444 | *Klebsiella michiganensis* |
| ISOLATE_874 | GCA_001598695.1 | NBRC 105695 | *Klebsiella oxytoca* |
| ISOLATE_9214 | GCA_902158725.1 | SB6412 | *Klebsiella pasteurii* |
| ISOLATE_116 | GCA_000281755.1 | DSM 30104 | *Klebsiella pneumoniae* |
| ISOLATE_1472 | GCA_000751755.1 | 01A030 | *Klebsiella quasipneumoniae* |
| ISOLATE_3288 | GCA_002269255.1 | KPN1705 | *Klebsiella quasivariicola* |
| ISOLATE_9231 | GCA_902158555.1 | SB6411 | *Klebsiella spallanzanii* |
| ISOLATE_331 | GCA_000828055.2 | DSM 15968 | *Klebsiella variicola* |
| ISOLATE_9178 | GCA_006711645.1 | DSM 102253 | *Raoultella electrica* |
| ISOLATE_1486 | GCA_001598295.1 | NBRC 105727 | *Raoultella ornithinolytica* |
| ISOLATE_1489 | GCA_000735435.1 | ATCC 33531 | *Raoultella planticola* |
| ISOLATE_8628 | GCA_900706855.1 | NCTC13038 | *Raoultella terrigena* |


# Results File

The MLSS.pl scan results (below) show the top match is ISOLATE_23. This is the type strain for *K.aerogenes* (NCBI Assembly ID: GCA_000215745.1).

ISOLATE_23 is matched with a rMLST-NI value of 99.94727% (column 4) and profile overlap of 100% (column 7).
The traffic light colour is 'Green' (column 6) indicating that this rMLST-NI value is within the range expected for
a match to the same species. The other matches have a traffic light colour of 'Red' indicating
that the rMLST-NI value is consistent with matches that do not share the same species as the associated profile.

For an explanation of the other fields in the results file, see the README file.

```
1	GCA_000534255.1_Ente_aero_UCI_27_V1_genomic.fna	ISOLATE_23	99.94727	Klebsiella aerogenes	Green	100.00000	51/51	20851/20862	20862/20862	41669	23	local
2	GCA_000534255.1_Ente_aero_UCI_27_V1_genomic.fna	ISOLATE_331	98.12081	Klebsiella variicola	Red	99.99041	51/51	20468/20860	20860/20862	39738	331	local
3	GCA_000534255.1_Ente_aero_UCI_27_V1_genomic.fna	ISOLATE_3288	97.56448	Klebsiella quasivariicola	Red	99.98083	51/51	20350/20858	20858/20862	39154	3288	local
4	GCA_000534255.1_Ente_aero_UCI_27_V1_genomic.fna	ISOLATE_1472	97.54075	Klebsiella quasipneumoniae	Red	99.99041	51/51	20347/20860	20860/20862	39133	1472	local
5	GCA_000534255.1_Ente_aero_UCI_27_V1_genomic.fna	ISOLATE_1486	97.51990	Raoultella ornithinolytica	Red	98.76330	50/51	20093/20604	20604/20862	38642	1486	local
6	GCA_000534255.1_Ente_aero_UCI_27_V1_genomic.fna	ISOLATE_1489	97.51480	Raoultella planticola	Red	98.75371	50/51	20090/20602	20602/20862	38633	1489	local
7	GCA_000534255.1_Ente_aero_UCI_27_V1_genomic.fna	ISOLATE_8556	97.50240	Klebsiella africana	Red	99.99041	51/51	20339/20860	20860/20862	39093	8556	local
8	GCA_000534255.1_Ente_aero_UCI_27_V1_genomic.fna	ISOLATE_116	97.47363	Klebsiella pneumoniae	Red	99.99041	51/51	20333/20860	20860/20862	39063	116	local
9	GCA_000534255.1_Ente_aero_UCI_27_V1_genomic.fna	ISOLATE_9178	97.40802	Raoultella electrica	Red	98.75371	50/51	20068/20602	20602/20862	38523	9178	local
10	GCA_000534255.1_Ente_aero_UCI_27_V1_genomic.fna	ISOLATE_874	97.37359	Klebsiella oxytoca	Red	100.00000	51/51	20317/20865	20865/20865	38977	874	local
11	GCA_000534255.1_Ente_aero_UCI_27_V1_genomic.fna	ISOLATE_2990	97.34433	Klebsiella grimontii	Red	99.99521	51/51	20307/20861	20861/20862	38941	2990	local
12	GCA_000534255.1_Ente_aero_UCI_27_V1_genomic.fna	ISOLATE_4277	97.33953	Klebsiella michiganensis	Red	99.99521	51/51	20306/20861	20861/20862	38936	4277	local
13	GCA_000534255.1_Ente_aero_UCI_27_V1_genomic.fna	ISOLATE_9214	97.32515	Klebsiella pasteurii	Red	99.99521	51/51	20303/20861	20861/20862	38921	9214	local
14	GCA_000534255.1_Ente_aero_UCI_27_V1_genomic.fna	ISOLATE_8579	97.17904	Klebsiella huaxiensis	Red	99.89935	51/51	20256/20844	20844/20865	38737	8579	local
15	GCA_000534255.1_Ente_aero_UCI_27_V1_genomic.fna	ISOLATE_9231	97.13341	Klebsiella spallanzanii	Red	99.99521	51/51	20263/20861	20861/20862	38721	9231	local
16	GCA_000534255.1_Ente_aero_UCI_27_V1_genomic.fna	ISOLATE_8628	96.84512	Raoultella terrigena	Red	98.75851	50/51	19953/20603	20603/20862	37945	8628	local
17	GCA_000534255.1_Ente_aero_UCI_27_V1_genomic.fna	ISOLATE_9164	96.51068	Klebsiella indica	Red	99.85622	51/51	20108/20835	20835/20865	38024	9164	local

```
