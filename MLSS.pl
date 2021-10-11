#! /usr/bin/perl -w
#--------------------------------------------------------
# PROGRAM: MLSS.pl
# AUTHOR:  James Bray
# CREATED: 22.03.2021
# UPDATED: ----------
# VERSION: v1.0.0
#
#--------------------------------------------------------
# VERSION HISTORY
# v1.0.0 (22.03.2021) original version
#
#--------------------------------------------------------
# COPYRIGHT NOTICE:
#
# Copyright (C) 2021 University of Oxford
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
#--------------------------------------------------------
# OVERVIEW:
# 
# MLSS: Multilocus Sequence Search
#
# Search bacterial genome sequences to identify DNA regions corresponding 
# with genes defined by multilocus sequence typing (MLST, rMLST etc) using a 
# library of sequence typing alleles. Calculate a nucleotide identity (NI) 
# for input allelic profiles (default: local identity calculation)
# 
# When used in conjuction with Ribosomal MLST (rMLST), this program can 
# be used for bacterial species identification.
#
# rMLST BACKGROUND:
#
# rMLST is a framework that defines the allelic variants (DNA sequences) 
# of 53 protein-encoding ribosomal genes (loci). Each variant is given a 
# unique numeric index per locus and the DNA sequences are stored in the rMLST 
# sequence definition database (available online with user registration at 
# https://pubmlst.org/species-id).
#
# Any genome can be expressed as an rMLST allelic profile, containing an 
# allelic index for each rMLST locus.
# 
# Similarity of a query genome with each rMLST profile is measured by a 
# nucleotide identity (NI) metric. Profile matches are optionally annotated 
# with a traffic light colour (Green, Amber, Red) based on the significance 
# of the match based on sequence identity values observed from a training dataset.
#
# Output is a scan results file, one profile match per line and ranked by 
# nucleotide identity (highest first).
#
# FILE AND DIRECTORY REQUIREMENTS:
# - A list of genomic sequence filenames
# - Name of the directory where the genomic sequence files are stored (warehouse directory)
# - A single FASTA file of rMLST allele sequences.
# - A single PROFILE file of profile definitions (tab separated text file)
#        One header row, followed by data rows
#        Each data row of the table contains the 'profile' data for that entity.
# - (Optional) A single ALLELE LENGTHS file. Allele length information for all entries in FASTA file
#        Not supplied on the command line.
#        Name must be FASTA_FILE.lengths and placed in the same directory as the FASTA file
#        Mirroring the BLAST index file naming convention
# - (Optional) A single THRESHOLDS file. Profile identity thresholds for all profile entries in PROFILE file
#        Used for calculating traffic light colour for reporting the significance of each reported 
#        nucleotide identity.
#
# PROTOCOL:
# 1. Read input files and perform data sanity checks
#       A. list of input QUERY genomic sequence filenames
# 	B. Read directory where these files are stored (WAREHOUSE)
#       C. ALLELE FASTA sequence library
#       D. PROFILE table file
#       E. (optional) ALLELE LENGTHS file
#       F. (optional) Profile THRESHOLDS file
#
#       Obtain additional information:
#       - If ALLELE LENGTHS not provided: read ALLELE FASTA file to obtain length information
#
#       Data sanity checks:
#	- Check all input genomic sequences exist in the warehouse directory
#       - If ALLELE LENGTHS provided: check all allele sequences in ALLELE FASTA file are present 
#       - If THRESHOLDS file provided: check all profile identifiers in PROFILE file are present 
#
# 2. Scan QUERY sequence again ALLELE FASTA sequence library
#       Results are output to a tabular format file.
#
# 3. Read tabular format file and extract the best match to each allele
#       Best match is based on raw score value.
#       Care is taken to account for allelic match results appearing reported per searched contig.
# 
# 4. Calculate the nucleotide identity (%) and percentage of overlap between genome and profile alleles
#
# 5. (optional) If THRESHOLDS file provided: calculate the traffic light colour for each profile match
#
# 6. Rank the PROFILE table entries by nucleotide identity (highest first) 
#       Write one results file per input QUERY file
#
# 7. Repeat for all input QUERY files
#
#
#--------------------------------------------------------
# CALCULATIONS:
#
# Calculate LOCAL Sequence Identity:
# Identity (%) = 100 x ( total identical matches [A] / total of aligned allele lengths [B] )
#
# Aligned allele length is calculated from the start and stop positions of the match 
# (allele sequence) reported by BLAST. Total aligned allele length is the sum of all allele match lengths.
#
# Calculate GLOBAL Sequence Identity:
# Identity (%) = 100 x ( total identical matches [A] / total profile nucleotide count [C] )
#
# Therefore if a profile allele is not matched at all, the length of this allele IS counted
# in the identity calculation.
#
# Calculate Nucleotide Overlap:
# Overlap (%) = 100 x ( total of aligned allele lengths [B] / total profile nucleotide length [C] )
#
# Variables are set at the point they are calculated or read from file
# IdenticalNucleotideCount [A] ] independent of the identity calculation method
# MatchedNucleotideCount [B]   ]
# ProfileNucleotideCount [C]   ]
#
# SequenceIdentityDenominator ] dependent on the identity calculation method
# global id = 100 * A/C (denominator = C), local id = 100 * A/B (denominator = B)
#
# Where possible all the sequence identity and nucleotide overlap values are re-calculated
# from the nucleotide count integers (A,B,C) so that there are no problems with comparing
# numbers that have been rounded up/down.
#
#
#--------------------------------------------------------
# PROFILE TABLE SOURCE:
# There are two sources of profiles:
# ISOLATE database or the SEQDEF database
#
# Profile entries generated from Isolate database file using 'id' field are prefixed: 'ISOLATE_'
# Profile entries generated from Sequence Definition file using 'rST' field are prefixed: 'RST_'
# and those using 'ST' field are prefixed: 'ST_'
# 
# If required the thresholds file profile identifiers must match the identifier generated internally
# based on 'id' (ISOLATE_), 'rST' (RST_) or 'ST' (ST_)
#
#--------------------------------------------------------
#
# DATA NAMING CONVENTIONS:
# Locus Identifier e.g. BACT000035
# Allele Index e.g. 1
# Allele Identifier e.g. BACT000035_1 - concatenated using an underscore
# rST - ribosomal sequence type
# Isolate - record from the isolate database table
# id - 'id' field of isolate database table
# Profile Identifier - numeric value (isolate id, rST or ST)
# Profile Name - e.g. a concatenated string 'ISOLATE_1', 'RST_1' or 'ST_1' - prefix describes profile source
# Profile Alias - field used for storing another name/identifier as required
#
#--------------------------------------------------------
use strict;
use warnings;
use English;
use FileHandle;
use Carp;
use List::Util qw(min max);
use Log::Log4perl qw(get_logger);
use File::Spec qw(rel2abs);
use Cwd;
use Parallel::ForkManager;
use File::Basename;
use FindBin;

use version;
our $VERSION = version->declare('v1.0.0');
our $AUTHOR = 'James Bray';
our $COPYRIGHT = 'Copyright (C) 2021 University of Oxford';

# Library Modules
use lib "$FindBin::Bin/lib";
use DefaultLoggerConfig;
use GetListFromFile;
use NumericalChecks;
use ProfileTableReader;
use Profile;
use Allele;
use ScanThresholdsReader;
use ScanThresholdsEntry;
use PairwiseEntry;
use ScanEntry;
use ScanWriter;
use JTableReader;
use JTableEntry;

# Set Autoflush
$| = 1;

# Prototypes
sub Usage();
sub ReadAlleleLengthFile($$$$);
sub ReadSequenceFileForLengths($$$$);
sub CheckAlleleSequenceLengths($$);
sub CheckProfilesHaveThresholds($$);
sub GetRMLSTLociArray();
sub RunBlast($$$$$);
sub ReadBlastTabular($$$);
sub CalculateProfileScores($$$$$$);
sub FilterPairwiseEntryArray($$);
sub SortScanEntriesArray($$);
sub SetTrafficLightColours($$);
sub GetRootString($);
sub HasResultsFile($$);
sub HasLockFile($$);
sub CreateLockFile($$);
sub RemoveLockFile($$);
sub GetSequenceOnce($);

# Variables
# Command line
my $arg1_cnt = 0;
my $arg2_cnt = 0;
my $arg3_cnt = 0;
my $arg4_cnt = 0;
my $arg5_cnt = 0;
my $arg6_cnt = 0;
my $opt1_cnt = 0;
# Filenames & filehandles
my $fIn = '';
my $fOut = '';
my $fError = "error.log";
my $fDebug = "debug.log";
my $fInfo = "info.log";
my $fProfiles = '';
my $fDatabase = '';
my $fThresholds = '';
my $fLoci = '';
#_ Directories
my $dWarehouse;
my $dWorking = cwd() || croak "Cannot read current working directory from system $!";
#_ Defaults
my $EvalueCollect = 10;
my $seqIdCollect = 50;
my $minimumMatchOverlap = 50;
my $minimumMatchSequenceIdentity = 50;
my $deleteFiles = 1;
my $maxThreadsPerJob = 1;
my $highestMaxThreadsPerJob = 8;
my $firstLine = 0;
my $lastLine = 0;
my $maxJobs = 53;
my $jobs = 1;
my $wordSize = 30;
my $profileIdentifierField = 'id';
my $profileFeatureField = 'species';
my $readThresholdsFile = 0;
my $readLociFile = 0;
my $reportingLimit = 0; # write all results
my $loggerLevel = "INFO";
my $identityCalculationMethod = 'local';
my $blastTask = 'blastn';

# Get BLAST directory from %ENV if available
my $dBlastBin = '';
my $blastExecutable = "blastn";
if(exists $ENV{'BLAST_BIN_PATH'}) {
	$dBlastBin = $ENV{'BLAST_BIN_PATH'};
	$blastExecutable = "$dBlastBin/blastn";
};

#Command line options & setup filenames
for (my $i=0; $i<=$#ARGV; $i++)
{
	# Usage
	if($ARGV[$i] eq "-h")         { Usage(); exit; }
	if($ARGV[$i] eq "-v")         { printf "VERSION: %s\n", $VERSION; exit; }

	# Required Options
	if($ARGV[$i] eq "-in")        { $fIn = $ARGV[$i+1]; $arg1_cnt++; }
	if($ARGV[$i] eq "-dir")       { $dWarehouse = $ARGV[$i+1]; $arg2_cnt++; }
	if($ARGV[$i] eq "-db")        { $fDatabase = $ARGV[$i+1]; $arg3_cnt++; }
	if($ARGV[$i] eq "-profiles")  { $fProfiles = $ARGV[$i+1]; $arg4_cnt++; }
	if($ARGV[$i] eq "-out")       { $fOut = $ARGV[$i+1]; $arg5_cnt++; }
	if($ARGV[$i] eq "-field=id")  { $profileIdentifierField = 'id'; $arg6_cnt++; }
	if($ARGV[$i] eq "-field=rST") { $profileIdentifierField = 'rST'; $arg6_cnt++; }
	if($ARGV[$i] eq "-field=ST")  { $profileIdentifierField = 'ST'; $arg6_cnt++; }

	# Expert Options
	if($ARGV[$i] eq "--debug")  { $loggerLevel = 'DEBUG'; }
	if($ARGV[$i] eq "--info")      { $loggerLevel = 'INFO'; }

	if($ARGV[$i] eq "--thresholds")  { $fThresholds = $ARGV[$i+1]; $readThresholdsFile = 1; }
	if($ARGV[$i] eq "--loci")  { $fLoci = $ARGV[$i+1]; $readLociFile = 1; }
	if($ARGV[$i] eq "--limit")  { $reportingLimit = $ARGV[$i+1]; }

	if($ARGV[$i] eq "--blast_exe")  { $blastExecutable = $ARGV[$i+1]; }

	if($ARGV[$i] eq "--nodelete") { $deleteFiles = 0; }
	if($ARGV[$i] eq "--delete")   { $deleteFiles = 1; }

	if($ARGV[$i] eq "--evalue_collect")   { $EvalueCollect = $ARGV[$i+1]; }
	if($ARGV[$i] eq "--seqid_collect")    { $seqIdCollect = $ARGV[$i+1]; }
	if($ARGV[$i] eq "--seqid_cutoff")     { $minimumMatchSequenceIdentity = $ARGV[$i+1]; }
	if($ARGV[$i] eq "--overlap_cutoff")   { $minimumMatchOverlap = $ARGV[$i+1]; }

	if($ARGV[$i] =~ m/^--(first|start|begin)$/) { $firstLine = $ARGV[$i+1]; $opt1_cnt++; }
	if($ARGV[$i] =~ m/^--(last|stop|end)$/)  { $lastLine = $ARGV[$i+1]; $opt1_cnt++; }

	if($ARGV[$i] eq "--feature")   { $profileFeatureField = $ARGV[$i+1]; }

	if($ARGV[$i] eq "--task=blastn")     { $blastTask = 'blastn'; }
	if($ARGV[$i] eq "--task=megablast")     { $blastTask = 'megablast'; }

	if($ARGV[$i] eq "--method=local")     { $identityCalculationMethod = 'local'; }
	if($ARGV[$i] eq "--method=global")    { $identityCalculationMethod = 'global'; }

	if($ARGV[$i] eq "--word_size")   { $wordSize = $ARGV[$i+1]; }
	if($ARGV[$i] eq "--max_threads_per_job")  { $maxThreadsPerJob = $ARGV[$i+1]; }
	if($ARGV[$i] eq "--jobs") { $jobs = $ARGV[$i+1] || '1'; }
}

#--------------------------------------------
# Check for minimum number of command line argument variables
#--------------------------------------------
if($arg1_cnt != 1) { Usage(); printf "REQUIRED OPTION: -in <FILE> containing list of contigs/genome files\n"; exit; }
if($arg2_cnt != 1) { Usage(); printf "REQUIRED OPTION: -dir <DIR> Contigs/genome warehouse directory\n"; exit; }
if($arg3_cnt != 1) { Usage(); printf "REQUIRED OPTION: -db <FILE> Allele sequence databases\n"; exit; }
if($arg4_cnt != 1) { Usage(); printf "REQUIRED OPTION: -profiles <FILE> PROFILES file\n"; exit; }
if($arg5_cnt != 1) { Usage(); printf "REQUIRED OPTION: -out <FILE> Output results file\n"; exit; }
if($arg6_cnt != 1) { Usage(); printf "REQUIRED OPTION: -field=id or -field=rST\n"; exit; }

# Check line input values make sense
if($opt1_cnt == 1 || $opt1_cnt > 2) { Usage(); printf "Requires both range command line options to be specified\n"; exit; }
if($lastLine < $firstLine) { Usage(); printf "Requires first number in range to be <= last number in range\n"; exit; }
if(! IsInteger( $firstLine ) ) { Usage(); printf "First/last input lines must be numbers\n"; exit; }
if(! IsInteger( $lastLine ) ) { Usage(); printf "First/last input lines must be numbers\n"; exit; }

#--------------------------------------------
# File checks
#--------------------------------------------
if(! -e $fIn)       { Usage(); printf "File does not exist: $fIn\n"; exit; }
if(-e $fOut) { Usage(); print "OUTPUT FILE EXISTS: $fOut\n"; exit; }

if(! -e $fDatabase)       { Usage(); printf "File does not exist: $fDatabase\n"; exit; }
if(! -e $fProfiles)       { Usage(); printf "File does not exist: $fProfiles\n"; exit; }

# check for optional thresholds file (if required)
if($readThresholdsFile) {
	if(! -e $fThresholds) { Usage(); printf "File does not exist: $fThresholds\n"; exit; }
}

# check for optional loci file (if required)
if($readLociFile) {
	if(! -e $fLoci) { Usage(); printf "File does not exist: $fLoci\n"; exit; }
}

#--------------------------------------------
# Software/Program checks
#--------------------------------------------
# Check for BLAST executable
$blastExecutable =~ s/^\s+//;
if(! -e $blastExecutable) { Usage(); printf "BLAST executable not found: $blastExecutable\n"; exit; }

#--------------------------------------------
# Directory checks
#--------------------------------------------
if($dWarehouse !~ m/^\//) { $dWarehouse = File::Spec->rel2abs( $dWarehouse, $dWorking ); }
if(! -d $dWarehouse) { Usage(); printf "Warehouse directory does not exist: $dWarehouse\n"; exit; }
$dWarehouse =~ s/\/$//;

#--------------------------------------------
# Advanced option checks
#--------------------------------------------
if($maxThreadsPerJob ne '1') {
	if(! IsPositiveInteger($maxThreadsPerJob)) {
		Usage(); printf "OPTION: --max_threads_per_job [INTEGER] - must specify a positive integer\n"; exit;
	}
	if($maxThreadsPerJob > $highestMaxThreadsPerJob) { 
		Usage(); printf "OPTION: --max_threads_per_job [INTEGER] - Exceeded maximum threads per job of $highestMaxThreadsPerJob\n"; exit;
	}
}

if(! IsPositiveInteger( $jobs ) ) { Usage(); printf "Number of parallel BLAST jobs must be a number\n"; exit; }
if($jobs > $maxJobs) { Usage(); printf "Maximum number of parallel BLAST jobs is $maxJobs\n"; exit;  }

if(! IsPositiveInteger( $wordSize ) ) { Usage(); printf "BLAST word size must be a number\n"; exit; }
if($wordSize > 30) { Usage(); printf "Maximum BLAST word size is 30\n"; exit;  }
if($wordSize < 10) { Usage(); printf "Minimum BLAST word size is 10\n"; exit;  }

# Check reporting limit (default = 0)
if(! IsInteger( $reportingLimit ) ) { Usage(); printf "Reporting limit option: --limit <INTEGER> must a number\n"; exit; }

#--------------------------------------------
#_ Create error, debug and info filenames
#--------------------------------------------
$fError = sprintf "%s.error", $fOut;
if(-e $fError) { unlink $fError; }
$fDebug = sprintf "%s.debug", $fOut;
if(-e $fDebug) { unlink $fDebug; }
$fInfo = sprintf "%s.info", $fOut;
if(-e $fInfo) { unlink $fInfo; }

#--------------------------------------------
#_ Logging System Settings
#--------------------------------------------
my $config = DefaultLoggerConfig($loggerLevel);
$config =~ s/error\.log/$fError/;
$config =~ s/debug\.log/$fDebug/;
$config =~ s/info\.log/$fInfo/;
Log::Log4perl->init( \$config );
my $logger = get_logger();

#--------------------------------------------
#_ Set Parameter Object
#--------------------------------------------
my $oParameters = new ParameterHelper;
$oParameters->setBlastExecutable( $blastExecutable );
$oParameters->setBlastTask($blastTask);
$oParameters->setBlastWordSize($wordSize);
$oParameters->setSeqIdCollect( $seqIdCollect );
$oParameters->setEvalueCollect( $EvalueCollect );
$oParameters->setNumberOfThreadsPerJob( $maxThreadsPerJob );
$oParameters->setWorkingDirectory($dWorking);
$oParameters->setWarehouseDirectory($dWarehouse);
$oParameters->setMinimumMatchCoverage($minimumMatchOverlap);
$oParameters->setMinimumMatchSequenceIdentity($minimumMatchSequenceIdentity);
$oParameters->setReportingLimit($reportingLimit);
$oParameters->setIdentityCalculationMethod($identityCalculationMethod);
if($deleteFiles) { $oParameters->setToDeleteFiles(); }

#--------------------------------------------
# Report parameters to screen
#--------------------------------------------
$logger->info("----------");
$logger->info("PROGRAM: ", basename($PROGRAM_NAME) );
$logger->info("VERSION: ", $VERSION);
$logger->info("INPUT_FILE: ", $fIn);
$logger->info("PROFILES_FILE: ", $fProfiles);
$logger->info("SEQUENCE_DATABASE_FILE: ", $fDatabase);
$logger->info("OUTPUT_FILE: ", $fOut);
$logger->info("ERROR_FILE: ", $fError);
if($loggerLevel eq 'DEBUG') { $logger->info("DEBUG_FILE: ", $fDebug); }
$logger->info("INFO_FILE: ", $fInfo);
$logger->info("WORKING_DIRECTORY: ", $oParameters->getWorkingDirectory() );
$logger->info("CONTIGS_DIRECTORY: ", $oParameters->getWarehouseDirectory() );
$logger->info("BLAST_EXECUTABLE: ", $oParameters->getBlastExecutable() );
$logger->info("BLAST_TASK: ", $blastTask);
$logger->info("BLAST_WORD_SIZE: ", $oParameters->getBlastWordSize() );
$logger->info("SEQ_ID_COLLECT: ", $oParameters->getSeqIdCollect() );
$logger->info("E-VALUE_COLLECT: ", $oParameters->getEvalueCollect() );
$logger->info("NUMBER_OF_THREADS_PER_JOB: ", $oParameters->getNumberOfThreadsPerJob() );
$logger->info("NUMBER_OF_JOBS: ", $jobs );
$logger->info("MINIMUM_MATCH_COVERAGE: ", $oParameters->getMinimumMatchCoverage() );
$logger->info("MINIMUM_MATCH_SEQUENCE_IDENTITY: ", $oParameters->getMinimumMatchSequenceIdentity() );

if($oParameters->getReportingLimit() > 0 ) { $logger->info("REPORTING_LIMIT: ", $oParameters->getReportingLimit() ); }
else { $logger->info("REPORTING_LIMIT: N/A (SET TO REPORT ALL RESULTS)"); }

if($oParameters->deleteFiles() ) { $logger->info("DELETE_FILES: YES"); }
else { $logger->info("DELETE_FILES: NO"); }

if($opt1_cnt != 0) {
	$logger->info("READING_INPUT_FILE_FIRST_LINE: ", $firstLine);
	$logger->info("READING_INPUT_FILE_LAST_LINE: ", $lastLine);
}

if($readThresholdsFile) { $logger->info("THRESHOLDS_FILE: ", $fThresholds); }
else { $logger->info("THRESHOLDS_FILE: N/A"); }

if($readLociFile) { $logger->info("USER-DEFINED_LOCI_FILE: ", $fLoci); }

if($profileIdentifierField eq 'id') { $logger->info("PROFILE_IDENTIFIER_FIELD: 'id'"); }
elsif($profileIdentifierField eq 'rST') { $logger->info("PROFILE_IDENTIFIER_FIELD: 'rST'"); }
elsif($profileIdentifierField eq 'ST') { $logger->info("PROFILE_IDENTIFIER_FIELD: 'ST'"); }
else { $logger->fatal("PROFILE_IDENTIFIER_FIELD: Not set (exiting)"); exit; }

if($profileFeatureField eq '') { $logger->info("PROFILE_FEATURE_FIELD: N/A"); }
else { $logger->info("PROFILE_FEATURE_FIELD: '$profileFeatureField'"); }

$logger->info("IDENTITY_CALCULATION: ", $identityCalculationMethod);

#--------------------------------------------
#_ Check database file and index files exist
#--------------------------------------------
if(! -e "$fDatabase.nin") { Usage(); printf "File does not exist: $fDatabase.pin\n"; exit; }
if(! -e "$fDatabase.nhr") { Usage(); printf "File does not exist: $fDatabase.phr\n"; exit; }
if(! -e "$fDatabase.nsq") { Usage(); printf "File does not exist: $fDatabase.psq\n"; exit; }


#--------------------------------------------
#_ Read Input List File (list of query sequence files)
#--------------------------------------------
$logger->info("START READING FILES AND RUNNING CHECKS");

my $aSequenceFilenames = [];
if(! GetListFromFile( $fIn, $aSequenceFilenames, $firstLine, $lastLine ) ) {
	$logger->fatal("CANNOT READ INPUT FILE: $fIn"); exit;
}
my $total = scalar(@$aSequenceFilenames);
if($total == 0) {
	$logger->fatal("NO ENTRIES INPUT FILE: ", $fIn); exit;
}
$logger->info("INPUT SEQUENCE FILE ENTRIES: ", $total );
$oParameters->setTotalEntries($total);

#--------------------------------------------
# Check all QUERY SEQUENCE files are present 
#--------------------------------------------
my $errorCount = 0;
foreach my $fSequence ( @$aSequenceFilenames ) {
	if(! -e "$dWarehouse/$fSequence") {
		$logger->error("INPUT QUERY SEQUENCE FILE NOT FOUND: $fSequence");
		$errorCount++;
	}
}
if($errorCount > 0) {
	$logger->error("MISSING INPUT QUERY SEQUENCE FILES: $errorCount"); exit;
}

#-------------------------------------------
# Read the sequence files for allele length information
# also record the number of sequences
# $hDatabaseSequenceLengths
# KEY: allele identifier VALUE: allele length
# $hDatabaseSequenceCounts
# KEY: basename of database filename VALUE: Number of allele sequences
#-------------------------------------------
my $hDatabaseSequenceLengths = {};
my $hDatabaseSequenceCounts = {};

my $fDatabaseBasename = basename($fDatabase);

# $fDatabase has path information
my $fAlleleLengths = sprintf "%s.lengths", $fDatabase;
if(-e $fAlleleLengths) {
	$logger->info("READING ALLELE LENGTHS FILE: ", $fAlleleLengths);
	ReadAlleleLengthFile($fAlleleLengths, $fDatabaseBasename, $hDatabaseSequenceLengths, $hDatabaseSequenceCounts);
}
else {
	$logger->info("READING SEQUENCE FILE FOR ALLELE LENGTHS: ", basename($fDatabase) );
	my $rv = ReadSequenceFileForLengths( $fDatabase, $fDatabaseBasename, $hDatabaseSequenceLengths, $hDatabaseSequenceCounts );
	if(! $rv) {
		$logger->error("Problem reading sequence file for allele lengths: ", $fDatabase );
		exit;
	}
}

$logger->info("TOTAL NUMBER OF DATABASE ALLELES: ", scalar ( keys %{$hDatabaseSequenceLengths} ) );
if(scalar ( keys %{$hDatabaseSequenceLengths} ) == 0 ) {
	$logger->error("PROBLEM RETRIEVING SEQUENCE LENGTHS");
	exit;
}

#--------------------------------------------
#_ Read Input Loci File (if required)
#--------------------------------------------
my $aLociFromFile = [];
if($readLociFile) { 
	if(! GetListFromFile( $fLoci, $aLociFromFile, 0, 0 ) ) {
		$logger->fatal("CANNOT READ INPUT LOCI FILE: $fLoci"); exit;
	}
	if(scalar(@$aLociFromFile) == 0) {
		$logger->fatal("NO ENTRIES INPUT LOCI FILE: ", $fLoci); exit;
	}
	$logger->info("INPUT LOCI FILE ENTRIES: ", scalar(@$aLociFromFile) );
}

#-------------------------------------------
# Read the profile file
#-------------------------------------------
$logger->info("READING PROFILE TABLE FILE: ", basename($fProfiles) );
my $oProfileReader = new ProfileTableReader();

# profile identifier field is either 'id', 'rST' or 'ST'
$oProfileReader->setProfileIdentifierField( $profileIdentifierField );

# profile feature field (often 'species')
$oProfileReader->setProfileFeatureField( $profileFeatureField );

# Pass list of loci to extract from profile file
if($readLociFile) {  $oProfileReader->setLocusIdentifiers($aLociFromFile); }
else { $oProfileReader->setLocusIdentifiers( GetRMLSTLociArray() ); }

# Only read in alleles with positive numeric allele indexes
# ignoring '0', 'N', '' (empty) and values with square brackets
# but will read paralogous allele cells 'X;Y' if present
$oProfileReader->setToAcceptPositiveNumericAllelesOnly();

# Read the profile table & populate profile array
# returns EXIT_SUCCESS(1) or EXIT_FAILURE(0)
if(! $oProfileReader->readFile($fProfiles) ) {
	$logger->fatal("CANNOT READ PROFILE TABLE FILE: ", $fProfiles); exit;
}
my $aProfiles = $oProfileReader->getProfiles();
$logger->info("PROFILE COUNT: ", scalar( @$aProfiles ) );

#--------------------------------------------
# Data Sanity Check:
# Check all allele described in profiles file are in the sequence length hash
#--------------------------------------------
$logger->info("CHECKING PROFILE ALLELES <-> SEQUENCE LENGTH DATA CONSISTENCY");
my $alleleErrorCount = CheckAlleleSequenceLengths($aProfiles, $hDatabaseSequenceLengths);
if($alleleErrorCount > 0) {
	$logger->fatal("Missing at least one allele sequence length in Profile Library - cannot continue"); exit;
}
$logger->info("SEQUENCE LENGTH DATA: PASSED");

#--------------------------------------------
#_ Read Scan Thresholds Table
#--------------------------------------------
my $oScanThresholdsReader;
if($readThresholdsFile) {
	# create ScanThresholdsReader object
	$oScanThresholdsReader = new ScanThresholdsReader;	
	$logger->info("READING THRESHOLDS FILE: ", basename($fThresholds) );
	# Returns EXIT_FAILURE(0) if failed to read file
	if(! $oScanThresholdsReader->readFile($fThresholds)) {
		$logger->fatal("Cannot read Thresholds File: $fThresholds"); exit;
	}
	if(scalar keys %{ $oScanThresholdsReader->getHash() } == 0) {
		$logger->fatal("Thresholds hash is empty (expecting something): $fThresholds"); exit;
	}

	#--------------------------------------------
	# Data Sanity Check:
	# Check all profiles described in profiles file are in the thresholds file
	#--------------------------------------------
	$logger->info("CHECKING PROFILE NAMES <-> THRESHOLD DATA CONSISTENCY");
	my $alleleErrorCount = CheckProfilesHaveThresholds($aProfiles, $oScanThresholdsReader);
	if($alleleErrorCount > 0) {
		$logger->fatal("At least one profile missing threshold data - cannot continue"); exit;
	}
	$logger->info("THRESHOLD DATA CONSISTENCY: PASSED");

}

# Initialise counter
my $counter = 0;

# parallel operations - maximum = number of jobs variable
my $pm = new Parallel::ForkManager( $jobs ); 

#---------------------------------------
# Loop around all contig/genome files
#---------------------------------------
ENTRY: foreach my $fSequence ( @$aSequenceFilenames )
{
	# increment counter (outside the fork)
	$counter++;

	# Remove any path (just in case)
	$fSequence = basename($fSequence);

	# Start Fork
	$pm->start and next ENTRY; # do the fork

	$oParameters->setCounter($counter);
	$logger->info("[FILE=$counter/$total] ENTRY: $fSequence");

	# Create sequence filenames with full paths
	my $fSeqsFullPath = sprintf "%s/%s", $dWarehouse, $fSequence;

	# Check that remote sequence file exists
	if(! -e $fSeqsFullPath || -z $fSeqsFullPath ) {
		$logger->error("[FILE=$counter/$total] Missing or Empty Sequence File (skipping): ", $fSeqsFullPath);
		next ENTRY;
	}

	# Create output filenames
	my $fResults = sprintf "%s_RESULTS", GetRootString($fSequence);
	if(HasResultsFile($fResults, $dWorking) ) {
		$logger->info("[FILE=$counter/$total] Results File exists (skipping): ", $fResults);
		# Finish Fork
		$pm->finish; # do the exit in the child process
		next ENTRY;
	}

	if(HasLockFile($fResults, $dWorking) ) {
		$logger->info("[FILE=$counter/$total] Lock File exists (skipping): ", $fResults);
		# Finish Fork
		$pm->finish; # do the exit in the child process
		next ENTRY;
	}

	# Lock file functionality
	CreateLockFile($fResults, $dWorking);

	$logger->info("[FILE=$counter/$total] Starting BLAST searches: $fSequence");

	# Create output filenames
	# extract the basename of the database filename
	my $fBlast = sprintf "%s_%s_BLAST", GetRootString($fSequence), GetRootString( basename($fDatabase) );
	if(-e $fBlast) { unlink $fBlast; }

	# Run BLAST Search
	if(! RunBlast( $oParameters, $fSeqsFullPath, $fBlast, $fDatabase, $hDatabaseSequenceCounts ) ) {
		$logger->info("[FILE=$counter/$total] NO RESULTS FROM BLAST SEARCH [$fDatabase]: $fSequence");
	}

	# Array to hold pairwise BLAST match information (in PairwiseEntry objects)
	my $aPairwiseEntries = [];

	# Check for BLAST output file
	$logger->info("[FILE=$counter/$total] Reading BLAST output files: $fSequence");
	if(! -e $fBlast || -z $fBlast) {
		$logger->debug("[FILE=$counter/$total] No BLAST File [$fDatabase]: $fSequence");
		if($oParameters->deleteFiles() ) { if(-e $fBlast) { unlink $fBlast; } }
	}
	else {
		# Read BLAST output files
		# ReadBlastTabular will croak if the BLAST file cannot be opened for reading
		# ReadBlastTabular will exit upon file format error (should not happen)
		# will always return EXIT_SUCCESS 
		ReadBlastTabular( $oParameters, $fBlast, $aPairwiseEntries );
	}

	# Remove intermediate files if required
	if($oParameters->deleteFiles() ) {
		if(-e $fBlast) { unlink $fBlast; }
	}

	# CalculateProfileScores() runs even when there are no allele matches (stored in $aPairwiseEntries)
	my $aScanEntries = [];
	$logger->info("[FILE=$counter/$total] Calculating Profile Scores: $fSequence");
	CalculateProfileScores($oParameters, $aScanEntries, $fSequence, $aPairwiseEntries, $oProfileReader, 
		$hDatabaseSequenceLengths);

	# Only calculate traffic lights if a thresholds file has been processed
	if($readThresholdsFile) {
		# Calculate traffic light colours
		SetTrafficLightColours($aScanEntries, $oScanThresholdsReader);
	}

	# Write out results to output file
	my $fhResults = FileHandle->new( $fResults, "w" ) || croak "Cannot open output filehandle: $fResults";
	my $oScanWriter = new ScanWriter($fhResults, ScanWriter::SFF );
	$oScanWriter->setReportingLimit( $oParameters->getReportingLimit() );
	$logger->info("[FILE=$counter/$total] Writing scan results: $fSequence");
	$oScanWriter->print( $aScanEntries );
	$fhResults->close();

	# Check for output file in current directory
	if(! -e $fResults || -z $fResults) {
		$logger->error("SCAN OUTPUT FILE IS MISSING OR EMPTY: ", $fResults);
	}

	# Tidy up lock file
	RemoveLockFile($fResults, $dWorking);

	# Report that query sequence file scan has finished
	$logger->info("[FILE=$counter/$total] FINISHED: $fSequence");

	# Finish Fork
	$pm->finish; # do the exit in the child process
	next ENTRY;

}

$pm->wait_all_children;


$logger->info("END: Program finished running");
$logger->info("----------");

#_ Tidy up error file
if(-z $fError) { unlink( $fError ); }
if(-e $fError) { system("touch $fError"); }

#_ Tidy up debug file
if(-z $fDebug) { unlink( $fDebug ); }
if(-e $fDebug) { system("touch $fDebug"); }

#_ Tidy up info file
if(-z $fInfo) { unlink( $fInfo ); }
if(-e $fInfo) { system("touch $fInfo"); }

if(-e $fInfo) { system("mv -f $fInfo $fOut"); }

#-----------------------------------------------------------
#Subroutines
#-----------------------------------------------------------
sub Usage()
{
	printf "PROGRAM: %s\n", basename($PROGRAM_NAME);
	printf "VERSION: %s\n", $VERSION;
	printf "AUTHOR: %s\n", $AUTHOR;
	printf "COPYRIGHT: %s\n", $COPYRIGHT;
        print << 'EOU';

MLSS: Multilocus Sequence Search

Search bacterial genome sequences to identify DNA regions corresponding 
with genes defined by multilocus sequence typing (MLST, rMLST etc) using a 
library of sequence typing alleles. Calculate a nucleotide identity (NI) 
for input allelic profiles (default:local identity calculation)

When used in conjuction with Ribosomal MLST (rMLST), this program can 
be used for bacterial species identification.

Program Dependencies:
---------------------
METACPAN: Log::Log4perl
https://metacpan.org/pod/Log::Log4perl

Requires BLAST executable: blastn
Program uses environment variable BLAST_BIN_PATH to find the blast bin directory
Set this in your shell environment prior to running.

export BLAST_BIN_PATH=<path_to_your_blast_bin_directory>
e.g. /usr/bin

Module Requirements:
--------------------
Modules included with this distribution:

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

Input File Format: List of Genome/Contigs Files
------------------------------------------------
ISOLATE_1_A0_contigs.fa
ISOLATE_2_A0_contigs.fa

Input File Format: Genome Files
-------------------------------
Sequence format = FASTA

Input File Format: Allele Sequence File
---------------------------------------
Sequence format = FASTA

This file must be indexed using makeblastdb.
COMMAND: makeblastdb -in FASTA_FILE.fa -dbtype nucl
Must use the same BLAST version of makeblastdb as blastn
Program checks for 3 blast index files (ending  in .nin, .nsq, .nhr) 
to ensure that makeblastdb has been run.

Input File Format: Lengths File (Optional)
------------------------------------------
Optional file - NOT supplied on the command line.
Name must be FASTA_FILENAME.lengths and placed in the same directory as 
the allele sequence FASTA file (mirroring the BLAST index file naming convention).

Two column format (tab separated)
Column 1: Allele identifier
Column 2: Allele length

Example:
BACT000001_3577	1674
BACT000002_86	726
BACT000003_63	699

Input File Format: Profile Table
--------------------------------
Header line to contain (tab separated):
Minimally requires 'id', 'rST' or 'ST' and locus names. Cannot contain duplicate header values.
Example (truncated after two loci):
id	isolate	species	BACT000001	BACT000002

Data lines to contain profile id and allele identifiers:
Example (truncated after two loci):
23	KCTC 2190	Klebsiella aerogenes	3916	2949

Program searches the header line for a 'feature' associated with the profile
to report (default: species). If this is not present, the program will NOT complain.

Input File Format: Thresholds File
----------------------------------
Seven columns (tab separated):
Column 1: Profile Identifier (e.g. ISOLATE_1 or RST_1)
Column 2: Threshold A (range 0-100)
Column 3: Threshold A fraction (number/number, default: 0/0)
Column 4: Threshold B (range 0-100)
Column 5: Threshold B fraction (number/number, default: 0/0)
Column 6: Feature (string)
Column 7: Comments (default: N/A)

If the threshold fraction is present from observed data (ie. is not the default value) 
the threshold is internally re-calculated from the fraction to avoid using a number 
that has been rounded up/down in the traffic light colour calculation.

Example line (from observed data):
ISOLATE_23	98.84958	20622/20862	98.17371	20481/20862	Klebsiella aerogenes	N/A

Example line (generic values):
ISOLATE_8556	99.95000	0/0	99.75000	0/0	Klebsiella africana	N/A

Traffic Light System (of Identity Significance):
Threshold A is the lowest observed value (%) of a same feature match for this profile (e.g. species).
Threshold B is the highest observed value (%) of a different feature match for this profile.
Identity values between 100% and threshold A (inclusive) are labelled as Green
Identity values below threshold A and above threshold B are labelled as Amber.
Identity values equal to or below threshold B are labelled as Red.

File Format: Loci File (optional)
---------------------------------
Single column file of locus identifiers.
Overrides the internal list of 53 rMLST locus identifiers.
Identifiers must not contain spaces.

Output File Format: 
-------------------
SCAN RESULTS FILE FORMAT 2.2 (13 columns)
Tab separated format:
Column 1: Rank Number
Column 2: Contigs Filename
Column 3: Profile Name (string)
Column 4: Sequence Identity (%)
Column 5: Profile Feature (often species)
Column 6: Traffic Light Colour
Column 7: Nucleotide Overlap (%)
Column 8: Matched Allele Count  / Profile Allele Count
Column 9: Number of Identical Matches / Sequence Identity Denominator*
Column 10: Matched Nucleotide Count / Profile Nucleotide Count
Column 11: Total Blast Score
Column 12: Profile Numeric Identifier
Column 13: Identity Calculation Method (global/local)

*NOTE: Sequence Identity Denominator depends on the identity calculation method
global = Profile Nucleotide Count, local = Matched Nucleotide Count

Example:
1	ISOLATE_23_A0_contigs.fa	ISOLATE_23	100.00000	Klebsiella aerogenes	Green	100.00000	51/51	20862/20862	20862/20862	20862	23	global
2	ISOLATE_23_A0_contigs.fa	ISOLATE_331	98.14016	Klebsiella variicola	Red	99.99041	51/51	20474/20862	20860/20862	19687	331	global
3	ISOLATE_23_A0_contigs.fa	ISOLATE_3288	97.58412	Klebsiella quasivariicola	Red	99.98083	51/51	20358/20862	20858/20862	19340	3288	global

Output filename for each query:
-------------------------------
Root of the input genome filename (before the dot) appended with '_RESULTS'.
Example: 'ISOLATE_23_A0_contigs.fa' produces a results file named 'ISOLATE_23_A0_contigs_RESULTS'

Temporary filenames
-------------------
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
QUERY_AlleleFasta_BLAST.tmp (unsorted file)
QUERY_AlleleFasta_BLAST (sorted file)


Output Error File
-----------------
Program reports missing BLAST output files to the error file

Usage:
------
Standard Options:
-h         - print usage instructions
-v         - print program version

Advanced Options (double dash):
--delete   - Delete individual BLAST files [default]
--nodelete - Do not delete BLAST files

--seqid_collect [NUMBER] Minimum sequence identity (%) used by BLAST to collect matches (Default: 50)
--evalue_collect [NUMBER] Minimum E-value used by BLAST to collect matches (Default: 10)

--max_threads_per_job [INTEGER] Maximum CPU threads BLAST uses per job/search (Default: 1)

--seqid_cutoff [NUMBER] Minimum sequence identity (%) of a collected match to 
               include in identity calculation (Default: 50)
--overlap_cutoff [NUMBER] Minimum match overlap (%) of a collected match to 
               include in identity calculation (Default: 50)

--jobs [INTEGER] Number of BLAST jobs to run in parallel (Default: 1)
--loci <FILE> List of loci to extract from profile table
--limit [INTEGER] Limit number of lines in each results files (Default: 0 = no limit)

--feature [STRING] string in profile header line for required profile feature [Default: species)

--method=global ] Calculate nucleotide identity globally
--method=local  ] Calculate nucleotide identity locally (Default: local)
                  (only count overlapping regions of profile alleles)

--task=blastn    ] BLASTN '-task [OPTION]' (Default: blastn)
--task=megablast ]

--first [INTEGER]  first entry in input list of query sequence files to process
--last [INTEGER]  last entry in input list of query sequence files to process

Required Options (single dash):
-in       <FILE> filename of input list of genome/contig files
-dir      <DIRECTORY> Genome/contig directory
-db       <FILE> Root filename of BLAST indexed sequence database>
-profiles <FILE> Profiles filename
-out      <FILE> LOG FILE (Error file: OutputFilename.error)

-field=id   ] select one of these profile identifier field options
-field=rST  ] 
-field=ST   ] 

Typical Usage:

MLSS.pl \
-in LIST_ContigsFiles.txt \
-dir ./contigs \
-db SEQS_Alleles.fa  \
-profiles PROFILES.txt \
-field=id \
-out LOGFILE.txt

EOU
}

#-----------------------------------------------------------
# Function: ReadAlleleLengthFile
#-----------------------------------------------------------
sub ReadAlleleLengthFile($$$$)
{
	my ($fLengths, $fDatabaseBasename, $hLengths, $hCounts) = @ARG;

	my $logger = get_logger();

	my $fhLengths = FileHandle->new( $fLengths, "r" ) || croak "Cannot open input filehandle: $fLengths";

	my $count = 0;

	# loop through all entries
	LINE: while(my $line = $fhLengths->getline)
	{
		chomp $line;
		if($line eq "") {
			$logger->error("Empty line in input list file (skipping): ", $fLengths);
			next LINE;
		}
		my @flds = split /\t/, $line;
		if(scalar(@flds) != 2) { $logger->fatal("Format Error in file: ", $fLengths); exit; } 
		if(! exists $hLengths->{$flds[0]} ) {
			$hLengths->{$flds[0]} = $flds[1];
			$count++;
		}
		else {
			$logger->error("Duplicate Entry in Sequence Length file: ", $flds[0]);
		}
	}

	# Save number of sequences in file
	$hCounts->{$fDatabaseBasename} = $count;

	$fhLengths->close;

	# EXIT_SUCCESS
	return 1;
}

#--------------------------------------------------------------------
# Function: ReadSequenceFileForLengths
#--------------------------------------------------------------------
sub ReadSequenceFileForLengths($$$$)
{
	my ( $fDatabase, $fDatabaseBasename, $hLengths, $hCounts ) = @ARG;

	# Logging System
	my $logger = get_logger();

	my $fhDatabase = FileHandle->new( "$fDatabase", "r" ) || croak "Cannot open database filehandle: $fDatabase";
	my $count = 0;

	# Get sequence data
	LINE: while( my $line = $fhDatabase->getline() )
	{
		# Skip comment lines
		if ($line =~ /^#/o ) { next LINE; }

		# Pattern match for sequence headers
		if ( $line =~ /^>(\S+)/ ) 
		{ 
			my $header = $1;

			# GetSequenceOnce: accepts filehandle giving the start position of sequence
			# changes filehandle position for next header in the file and
			# also returns the sequence string
			my $wholeSequence = GetSequenceOnce($fhDatabase);

			# Calculate sequence length
			my $sequenceLength = length($wholeSequence);

			if(! exists $hLengths->{$header}) {
				$hLengths->{$header} = $sequenceLength;
			}
			else {
				$logger->error("Duplicate allele sequence found (skipping): ", $header);
			}

			$count++;
		}
	}

	# Save number of sequences in file
	$hCounts->{$fDatabaseBasename} = $count;

	$fhDatabase->close();

	# EXIT_SUCCESS
	return 1;
}

#--------------------------------------------------------------------
# Function: CheckAlleleSequenceLengths
#--------------------------------------------------------------------
sub CheckAlleleSequenceLengths($$)
{
	my ($aProfiles, $hDatabaseSequenceLengths) = @ARG;

	# Logging System
	my $logger = get_logger();

	my $alleleErrorCount = 0;

	PROFILE: foreach my $oProfile ( @$aProfiles )		
	{
		my $aAlleles = $oProfile->getAlleles();
		ALLELE: foreach my $oAllele ( @$aAlleles )
		{
			my $alleleIdentifier = $oAllele->getAlleleIdentifier();
			# Check that allele identifier exists in $hDatabaseSequenceLengths
			if(! exists $hDatabaseSequenceLengths->{$alleleIdentifier} ) {
				$logger->error("DATABASE ALLELE SEQUENCE LENGTH NOT FOUND: ", $alleleIdentifier);
				$alleleErrorCount++;
			}
		}
	}
	return $alleleErrorCount;
}

#--------------------------------------------------------------------
# Function: CheckProfilesHaveThresholds
#--------------------------------------------------------------------
sub CheckProfilesHaveThresholds($$)
{
	my ($aProfiles, $oScanThresholdsReader) = @ARG;

	# Logging System
	my $logger = get_logger();

	my $profileErrorCount = 0;

	# get hash of thresholds
	# key = profileName value = $oScanThreshold
	my $hThresholds = $oScanThresholdsReader->getHash();

	PROFILE: foreach my $oProfile ( @$aProfiles )		
	{
		my $profileName = $oProfile->getName();
		if(! exists $hThresholds->{$profileName}) {
			$logger->error("PROFILE ENTRY NOT FOUND IN THRESHOLD TABLE: ", $profileName);
			$profileErrorCount++;
		}
	}
	return $profileErrorCount;
}

#-----------------------------------------------------------
# Function: GetRMLSTLociArray
#-----------------------------------------------------------
sub GetRMLSTLociArray()
{
	my $a = [ 'BACT000001', 'BACT000002', 'BACT000003', 'BACT000004', 'BACT000005', 'BACT000006', 
	'BACT000007', 'BACT000008', 'BACT000009', 'BACT000010', 'BACT000011', 'BACT000012', 'BACT000013',
	'BACT000014', 'BACT000015', 'BACT000016', 'BACT000017', 'BACT000018', 'BACT000019',
	'BACT000020', 'BACT000021', 'BACT000030', 'BACT000031', 'BACT000032',
	'BACT000033', 'BACT000034', 'BACT000035', 'BACT000036', 'BACT000038', 'BACT000039',
	'BACT000040', 'BACT000042', 'BACT000043', 'BACT000044', 'BACT000045', 'BACT000046', 
	'BACT000047', 'BACT000048', 'BACT000049', 'BACT000050', 'BACT000051',
	'BACT000052', 'BACT000053', 'BACT000056', 'BACT000057', 'BACT000058', 'BACT000059',
	'BACT000060', 'BACT000061', 'BACT000062', 'BACT000063', 'BACT000064', 'BACT000065' ];

	return $a;
}


#---------------------------------------------------------------
# Function: RunBlast
#---------------------------------------------------------------
#
# BLAST TABULAR OPTIONS
# Tabular formatting options are described here:
# https://www.ncbi.nlm.nih.gov/books/NBK279684/
#
# 13 column output
# "-outfmt '6 qseqid sseqid qlen slen qstart qend sstart send pident length evalue score nident' ";
#
# qseqid: Query Seq-id [id=identifier]
# sseqid: Subject Seq-id [id=identifier]
# qlen: Query length [Undocumented]
# slen: Subject length [Undocumented]
# qstart: Start of alignment in query
# qend: End of alignment in query
# sstart: Start of alignment in subject
# send: End of alignment in subject
# pident: Percentage of identical matches
# length: Alignment length
# evalue: Expect value
# score: Raw score
# nident: Number of identical matches
#
#---------------------------------------------------------------
sub RunBlast($$$$$)
{
	my ( $oParameters, $fIn, $fBlastOut, $fDatabase, $hDatabaseSeqCounts ) = @ARG;

	# Logging
	my $logger = get_logger();

	# Entry Counter
	my $counter = $oParameters->getCounter();
	my $total = $oParameters->getTotalEntries();

	# Get BLAST parameters
	my $blastExecutable = $oParameters->getBlastExecutable();
	my $wordSize = $oParameters->getBlastWordSize();
	my $maxThreadsPerJob = $oParameters->getNumberOfThreadsPerJob();
	my $EvalueCollect = $oParameters->getEvalueCollect();
	my $seqIdCollect = $oParameters->getSeqIdCollect();
	my $blastTask = $oParameters->getBlastTask();

	# Create a temporary BLAST output filename
	my $fBlastOutTmp = sprintf "%s.tmp", $fBlastOut;
	if(-e $fBlastOutTmp) { unlink $fBlastOutTmp; }

	# read database size (number of sequences in BLAST library file)
	my $fDatabaseBasename = basename($fDatabase);
	my $databaseSize = 0;
	if(exists $hDatabaseSeqCounts->{$fDatabaseBasename}) {
		$databaseSize = $hDatabaseSeqCounts->{$fDatabaseBasename};
	}
	else {
		$logger->fatal("No database size entry for file: ", $fDatabase);
		exit;
	}

	# BLAST command
	# Options:
	# perc_identity <integer> Percent identity cutoff.
	# evalue <real> Expect value (E) for saving hits

	# blastn command by default runs megablast.
	# specify '-task blastn'

	my $command = "$blastExecutable -task $blastTask -word_size $wordSize ";
	if($maxThreadsPerJob > 1) { $command .= sprintf "-num_threads %d ", $maxThreadsPerJob; }
	$command .= "-query $fIn -db $fDatabase -out $fBlastOutTmp -evalue $EvalueCollect -perc_identity $seqIdCollect -dust no ";
	$command .= "-outfmt '6 qseqid sseqid qlen slen qstart qend sstart send pident length evalue score nident' ";
	# Add -max_target_seqs value that exceeds number of alleles in database
	$command .= sprintf "-max_target_seqs %d ", $databaseSize * 2;

	# Run the BLAST command
	$logger->debug("[FILE=$counter/$total] RUNNING COMMAND: $command");
	system( $command );
	
	if(! -e $fBlastOutTmp || -z $fBlastOutTmp) { 
		$logger->debug("[FILE=$counter/$total] No BLAST Output File: $fBlastOutTmp"); 
		if(-e $fBlastOutTmp) { unlink( $fBlastOutTmp ); }
		return 0;
	}

	# Sorting the BLAST tabular file is required (cannot rely on BLAST to put 
	# the best match first when there are sequence matches on different contigs)
	# This program only extracts ONE allele match per input query file. So 
	# requires this to be the ranked at the top of the BLAST output file.
	#
	# Sort BLAST tabular file: sort -k2,2 -k12,12nr -k9,9nr -k10,10nr
	# 1. Allele Id (alphabetical)
	# 2. Raw Score (reverse numeric [highest first])
	# 3. Seq ID (reverse numeric [highest first]
	# 4. Match Length (reverse numeric [highest first]
	my $commandSort = "sort -k2,2 -k12,12nr -k9,9nr -k10,10nr $fBlastOutTmp > $fBlastOut";
	$logger->debug("[FILE=$counter/$total] RUNNING COMMAND: $commandSort");
	system( $commandSort );

	# Remove temporary file
	if(-e $fBlastOutTmp) { unlink( $fBlastOutTmp ); }

	# Check for Sorted BLAST file & report if missing
	if(! -e $fBlastOut || -z $fBlastOut) { 
		$logger->error("[FILE=$counter/$total] No SORTED BLAST Output File: $fBlastOut"); 
		if(-e $fBlastOut) { unlink( $fBlastOut ); }
		return 0;
	}

	# EXIT_SUCCESS
	return 1;
}

#---------------------------------------------------------------
# Function: ReadBlastTabular
#---------------------------------------------------------------
sub ReadBlastTabular($$$)
{
	my ($oParameters, $fBlast, $aPairwiseEntries) = @ARG;

	#_ Logging system
	my $logger = get_logger();

	# Entry Counter
	my $counter = $oParameters->getCounter();
	my $total = $oParameters->getTotalEntries();

	$logger->debug("[FILE=$counter/$total] READING BLAST FILE: $fBlast");

	my $fhBlast = FileHandle->new( $fBlast, "r" ) || croak "Cannot open input filehandle: $fBlast";

	# loop through all entries
	LINE: while(my $line = $fhBlast->getline)
	{
		chomp $line;
		if($line eq "") {
			$logger->error("Empty line in BLAST tabular file (skipping): $fBlast\n");
			next LINE;
		}

		# 13 column output
		# "-outfmt '6 qseqid sseqid qlen slen qstart qend sstart send pident length evalue score nident' ";
		my $oPairwiseEntry = new PairwiseEntry;
		my @flds = split /\s+/, $line;
		# Check for 13 fields
		if(scalar(@flds)!=13) { 
			$logger->fatal("Problem with BLAST tabular format: Expect 13 columns: $line");
			exit;
		}

		my $evalue = $flds[10];
		my $logEvalue;
		if($evalue == 0) { $logEvalue = 300; }
		else { $logEvalue = -(log($evalue) / log(10) ); }

		# Adjust for strand orientation
		# start / stop numbers get reversed on negative strand
		my $orientation = 'UNKNOWN';

		# ONLY MATCH START/STOP THAT CAN BE REVERSED (NOT QUERY)
		if($flds[4] < $flds[5]) { $orientation = 'FORWARD'; } 
		else { $orientation = 'REVERSE'; }

		my $querySegmentStart = min $flds[4], $flds[5];
		my $querySegmentEnd = max $flds[4], $flds[5];
		my $matchSegmentStart = min $flds[6], $flds[7];
		my $matchSegmentEnd = max $flds[6], $flds[7];

		$oPairwiseEntry->setQuerySeqName($flds[0]);
		$oPairwiseEntry->setMatchSeqName($flds[1]);
		$oPairwiseEntry->setQuerySeqLength($flds[2]);
		$oPairwiseEntry->setMatchSeqLength($flds[3]);
		$oPairwiseEntry->setQuerySegmentStart($querySegmentStart);
		$oPairwiseEntry->setQuerySegmentEnd($querySegmentEnd);
		$oPairwiseEntry->setMatchSegmentStart($matchSegmentStart);
		$oPairwiseEntry->setMatchSegmentEnd($matchSegmentEnd);
		$oPairwiseEntry->setSeqId($flds[8]);
		$oPairwiseEntry->setTotalSegmentLength($flds[9]);
		$oPairwiseEntry->setEvalue($flds[10]);
		$oPairwiseEntry->setLogEvalue($logEvalue);
		$oPairwiseEntry->setScore($flds[11]);
		$oPairwiseEntry->setIteration('1');
		$oPairwiseEntry->setStrandOrientation($orientation);
		$oPairwiseEntry->setNumberOfIdenticalMatches($flds[12]);

		# others
		$oPairwiseEntry->setQuerySegmentLength( $querySegmentEnd - $querySegmentStart + 1 );
		$oPairwiseEntry->setMatchSegmentLength( $matchSegmentEnd - $matchSegmentStart + 1 );

		push @$aPairwiseEntries, $oPairwiseEntry;
	}

	$fhBlast->close;

	# EXIT_SUCCESS
	return 1;
}

#---------------------------------------------------------------
# Function: CalculateProfileScores
#---------------------------------------------------------------
sub CalculateProfileScores($$$$$$)
{
        my ($oParameters, $aScanEntries, $fContigFilename, $aPairwiseEntries, 
		$oProfileReader, $hDatabaseSequenceLengths ) = @ARG;

	#_ Logging system
	my $logger = get_logger();

	# Get array of profiles
	my $aProfiles = $oProfileReader->getProfiles(); # just gets the array
	$logger->debug("PROFILE ENTRIES: ", scalar( @$aProfiles ) );
	if(scalar(@$aProfiles) == 0) {
		$logger->fatal("NO PROFILES IN FILE OR PROFILE ARRAY NOT SET: ", $fProfiles); exit;
	}

	# Get Thresholds for a valid match
	my $minimumMatchSequenceIdentity = $oParameters->getMinimumMatchSequenceIdentity();
	my $minimumMatchOverlap = $oParameters->getMinimumMatchCoverage();

	# read SCAN file - save results in hash table = $hAlleleScan
	# keys = allele_id values = PairwiseEntry objects
	# NOTE: $hAlleleScan could be empty hash if no matches were found after filtering
	my $hAlleleScan = {};
	FilterPairwiseEntryArray($aPairwiseEntries, $hAlleleScan);

	# initialise profile counter
	my $profileCounter = 0;

	# initialise scan entry array
	my $aScanEntriesUnsorted = [];

	# Loop around all profiles in the reference isolate set
	# to calculate the sequence identity for each profile
	PROFILE: foreach my $oProfile ( @$aProfiles )		
	{
		# Save all information for ONE profile in ONE ScanEntry object
		# Create new Scan entry
		my $oScanEntry = new ScanEntry;

		$oScanEntry->setContigsFilename( basename( $fContigFilename ) );
		$oScanEntry->setProfilesFilename( basename( $oProfileReader->getFileName() ) );

		# ProfileName is ISOLATE_1 or RST_1 (ProfileNumericIdentifier is 1)
		$oScanEntry->setProfileName( $oProfile->getName() );
		$oScanEntry->setProfileFeature( $oProfile->getFeature() );
		$oScanEntry->setProfileNumericIdentifier( $oProfile->getIdentifier() );

		# local variables
		my $matchedAlleleCount = 0;
		my $scanAlleleCounter = 0;
		my $totalBlastScore = 0;
		my $profileNucleotideCount = 0;
		my $matchedNucleotideCount = 0;
		my $identicalNucleotideCount = 0;
		my $profileName = $oProfile->getName();

		$profileCounter++;
		$logger->debug("[$profileCounter; $profileName] PROFILE NAME: ", $profileName );

		# loop around all alleles in this reference isolate/profile
		# HASH: $hProfileAlleles
		# key = AlleleIdentifier, value = PairwiseEntry object (use getScore() method)
		# Count up BLAST scores to give total BLAST score value
		my $hProfileAlleles = $oProfile->getHashByAlleleIdentifier();

		my $profileAlleleCount = 0;

		# no need to sort the alleles (unless debugging)
		PROFILE_ALLELE: foreach my $profileAlleleIdentifier ( keys %{$hProfileAlleles} )
		{
			$logger->debug("[$profileCounter; $profileName] PROFILE ALLELE: ", $profileAlleleIdentifier );

			# Ignores profile alleles containing 'N', square brackets or blank cells
			# These have now been filtered out by ProfileTableReader module

			# Only count 'real' alleles
			$profileAlleleCount++;

			# Get Database sequence lengths (for profile alleles)
			if(exists $hDatabaseSequenceLengths->{$profileAlleleIdentifier} ) {
				$profileNucleotideCount += $hDatabaseSequenceLengths->{$profileAlleleIdentifier};
			}
			# Should not happen (we checked all allele lengths were present in main)
			else {
				$logger->fatal("DATABASE ALLELE SEQUENCE LENGTH NOT FOUND: ", $profileAlleleIdentifier);
				exit;
			}

			$logger->debug("[$profileCounter; $profileName] ALLELE LENGTH: ", 
				$hDatabaseSequenceLengths->{$profileAlleleIdentifier} );

			# Calculate total identical bases for valid allele matches
			if(exists $hAlleleScan->{$profileAlleleIdentifier} ) {

				$logger->debug("[$profileCounter; $profileName] PROFILE ALLELE EXISTS IN HASH hAlleleScan: ", $profileAlleleIdentifier );

				my $oPairwiseEntry = $hAlleleScan->{$profileAlleleIdentifier};

				# FILTER OUT MATCHES BELOW SEQID & OVERLAP CRITERIA
				if($oPairwiseEntry->getSeqId() < $minimumMatchSequenceIdentity ) {
					$logger->debug("[$profileCounter] FILTER OUT ALLELE: $profileAlleleIdentifier SEQID: ", $oPairwiseEntry->getSeqId());
					next PROFILE_ALLELE;
				}
				my $matchOverlap = 100 * $oPairwiseEntry->getMatchSegmentLength() / $oPairwiseEntry->getMatchSeqLength();
				if( $matchOverlap < $minimumMatchOverlap ) {
					$logger->debug("[$profileCounter] FILTER OUT ALLELE: $profileAlleleIdentifier OVERLAP: ", $matchOverlap);
					next PROFILE_ALLELE;
				}

				my $identicalNucleotides = $oPairwiseEntry->getNumberOfIdenticalMatches() || 0;
				$identicalNucleotideCount += $identicalNucleotides;
				$logger->debug("[$profileCounter; $profileName] ALLELE IDENTICAL NUCLEOTIDES: $identicalNucleotides");
				$logger->debug("[$profileCounter; $profileName] CALCULATING TOTAL IDENTICAL NUCLEOTIDES: $identicalNucleotideCount");

				my $blastScore = $oPairwiseEntry->getScore() || 0;
				$totalBlastScore += $blastScore;
				$logger->debug("[$profileCounter; $profileName] BLAST SCORE: $blastScore");
				$logger->debug("[$profileCounter; $profileName] CALCULATING TOTAL BLAST SCORE: $totalBlastScore");

				# increment the allele match counter
				$matchedAlleleCount++;

				$matchedNucleotideCount += $oPairwiseEntry->getMatchSegmentLength();
			}
		}

		$logger->debug("[$profileCounter; $profileName] TOTAL_BLAST_SCORE: $totalBlastScore ", $oProfile->getName() );
		$logger->debug("[$profileCounter; $profileName] ALLELE_MATCH_COUNTER: $matchedAlleleCount ",$oProfile->getName() );
		$logger->debug("[$profileCounter; $profileName] MATCHED_NUCLEOTIDE_COUNT: $matchedNucleotideCount ",$oProfile->getName() );
		$logger->debug("[$profileCounter; $profileName] PROFILE_NUCLEOTIDE_COUNT: $profileNucleotideCount ",$oProfile->getName() );
		$logger->debug("[$profileCounter; $profileName] IDENTICAL_NUCLEOTIDE_COUNT: $identicalNucleotideCount ",$oProfile->getName() );

		# Save data in ScanEntry object
		$oScanEntry->setTotalBlastScore( $totalBlastScore );
		$oScanEntry->setProfileNucleotideCount( $profileNucleotideCount );
		$oScanEntry->setMatchedNucleotideCount( $matchedNucleotideCount );
		$oScanEntry->setIdenticalNucleotideCount( $identicalNucleotideCount );
		$oScanEntry->setMatchedAlleleCount( $matchedAlleleCount );
		$oScanEntry->setProfileAlleleCount( $profileAlleleCount );

		# Calculate Sequence Identity - Two methods
		# Value set as it is required for sorting results
		# Also protect against division by zero
		my $sequenceIdentity = 0;

		# GLOBAL calculation:
		# Divide total identical matches by profile nucleotide count
		if(lc($oParameters->getIdentityCalculationMethod()) eq 'global') {
			$oScanEntry->setSequenceIdentityDenominator($profileNucleotideCount);
		}
		# LOCAL calculation:
		# Divide total identical matches by matched nucleotide count
		elsif(lc($oParameters->getIdentityCalculationMethod()) eq 'local') {
			$oScanEntry->setSequenceIdentityDenominator($matchedNucleotideCount);
		}

		if($oScanEntry->getSequenceIdentityDenominator() != 0) {
			$sequenceIdentity = 100 * 
				$oScanEntry->getIdenticalNucleotideCount() /
				$oScanEntry->getSequenceIdentityDenominator();
		}

		# Sequence identity is set here as used in sort rountine
		$oScanEntry->setSequenceIdentity( $sequenceIdentity );
		$oScanEntry->setIdentityCalculationMethod( lc($oParameters->getIdentityCalculationMethod()) );

		# add to array
		push @$aScanEntriesUnsorted, $oScanEntry;
	}

	# Sort by Sequence Identity
	SortScanEntriesArray( $aScanEntriesUnsorted, $aScanEntries );

	# EXIT_SUCCESS
	return 1;
}

#-----------------------------------------------------------
# Function: FilterPairwiseEntryArray
#
# EXIT: Success(1) or Failure(0)
#-----------------------------------------------------------
sub FilterPairwiseEntryArray($$)
{
	my ($aPairwiseEntries, $hResults) = @ARG;

	# Logging
	my $logger = get_logger();

	# Read Scan Pair lines
	ENTRY: foreach my $oPairwiseEntry ( @$aPairwiseEntries )
	{
		my $alleleIdentifier = $oPairwiseEntry->getMatchSeqName();

		# Only save first observed match per allele 
		# (THERE ARE SOMETIMES MORE THAN ONE MATCH PER ALLELE IN THE FILE)
		# save Pairwise entry object in hash
		if(! exists $hResults->{$alleleIdentifier} ) {
			$hResults->{$alleleIdentifier} = $oPairwiseEntry;
		}
		# Silently ignore secondary matches 
		#else {
		#	$logger->error("Duplicate Allele in pairwise array [$alleleIdentifier]");
		#}
	}

	# EXIT_FAILURE
	if(scalar( keys %$hResults ) == 0) {
		$logger->error("EMPTY ALLELE SCAN ARRAY");
		return 0;
	}

	# EXIT_SUCCESS
	return 1;
}

#-----------------------------------------------------------
# Function: SortScanEntriesArray
#
# Resolve sequence identity ties (e.g. 100%) with total blast score
# Make species sort case-insensitive
#
# Uses numeric profile identifier to avoid problems sorting an alphanumeric string
# (ISOLATE_12 before ISOLATE_4) so can give reliable output over time as
# higher numbers are added to the isolate/rST databases
#
# ORDER:
#	Sequence Identity (largest first)
#	TotalBlastScore (largest first)
#	Profile Feature (often species) [uppercase] (A->Z)
#	Profile Numeric Identifier (smallest first)
#
# EXIT: Success(1)
#-----------------------------------------------------------
sub SortScanEntriesArray($$)
{
        my ($aScanEntries) = $ARG[0];
        my ($aScanEntries_Sorted) = $ARG[1];

	#_ Logging system
	my $logger = get_logger();

	# Sort
	my $counter = 0;
	foreach my $oScanEntry ( sort { $b->getSequenceIdentity() <=> $a->getSequenceIdentity()  
				|| $b->getTotalBlastScore() <=> $a->getTotalBlastScore() 
				|| uc( $a->getProfileFeature() ) cmp uc( $b->getProfileFeature() ) 
				|| $a->getProfileNumericIdentifier() <=> $b->getProfileNumericIdentifier() } @$aScanEntries )
	{
		$counter++;
		$oScanEntry->setRankNumber($counter);
		push @$aScanEntries_Sorted, $oScanEntry;
	}

	# EXIT_SUCCESS
	return 1;
}

#-----------------------------------------------------------
# Function: SetTrafficLightColours
#
# EXIT: Success(1)
#-----------------------------------------------------------
sub SetTrafficLightColours($$)
{
	my ($aScanEntries, $oScanThresholdsReader) = @ARG;

	# Logging
	my $logger = get_logger();

	# HASH TABLE $hScanThresholds
	# KEY = ProfileIdentifier  VALUE = $oScanThresholdsEntry
	my $hScanThresholds = $oScanThresholdsReader->getHash();

	# Switch off warnings if statistics hash is empty
	my $warnForMissingStatistics = 1;
	if(scalar keys %{$hScanThresholds} == 0) {
		$warnForMissingStatistics = 0;
	}

	ENTRY: foreach my $oScanEntry ( @$aScanEntries )
	{
		# Get profile name for error reporting
		my $profileName = $oScanEntry->getProfileName();

		# Get ScanThresholdsEntry Object
		my $oScanThresholdsEntry;
		if(exists $hScanThresholds->{$profileName} ) {
			$oScanThresholdsEntry = $hScanThresholds->{$profileName};
		}
		else {
			if($warnForMissingStatistics) {
				$logger->error("CANNOT FIND SCAN THRESHOLDS ENTRY FOR: ", $profileName);
			}
			$oScanEntry->setTrafficLightColour('N/A');
			next ENTRY;
		}

		my $sequenceIdentity = $oScanEntry->getSequenceIdentity();

		# If Sequence Identity is Zero - Traffic Light is 'Red' (end of story)
		if($sequenceIdentity == 0) {
			$oScanEntry->setTrafficLightColour('Red');
			next ENTRY;
		}

		#-----------------------------------------------------
		# FEATURE TRAFFIC LIGHT COLOUR CALCULATIONS
		#-----------------------------------------------------

		# THRESHOLD SCENARIO 1:
		# Above Or Equal to Threshold A = Green
		if($sequenceIdentity >= $oScanThresholdsEntry->getThresholdA() ) {
			$oScanEntry->setTrafficLightColour('Green');
		}

		# THRESHOLD SCENARIO 2:
		# Between Threshold A and B = Amber
		elsif($sequenceIdentity < $oScanThresholdsEntry->getThresholdA() 
			&& $sequenceIdentity > $oScanThresholdsEntry->getThresholdB() ) {
			$oScanEntry->setTrafficLightColour('Amber');
		}

		# THRESHOLD SCENARIO 3:
		# Below Or Equal to Threshold B = Red
		elsif($sequenceIdentity <= $oScanThresholdsEntry->getThresholdB() ) {
			$oScanEntry->setTrafficLightColour('Red');
		}

		else {
			$oScanEntry->setTrafficLightColour('Red');
		}

	}

	#EXIT_SUCCESS
	return 1;
}

#---------------------------------------------------------------
# Function: GetRootString
#---------------------------------------------------------------
sub GetRootString($)
{
	my $string = $ARG[0];

	if($string =~ m/(\S+)\./) {
		return $1;
	} else {
		return $string;
	}
}

#-----------------------------------------------------------
# Method: HasResultsFile()
# Return: EXIT_SUCCESS(1) or EXIT_FAILURE(0)
#
# Check Contig Warehouse For Results File
#-----------------------------------------------------------
sub HasResultsFile($$)
{
	my ( $file, $d ) = @ARG;

	# Logging System
	my $logger = get_logger();

	$logger->debug("Directory: ", $d);
	$logger->debug("Checking directory for job results file: ", $file);

	if(! -e "$d/$file") {
		# EXIT_FAILURE(0) - Cannot find file
		$logger->debug("Results file ($file) not found in directory");
		return 0;
	}
	
	# EXIT_SUCCESS (1) - File is Present
	$logger->debug("Results file ($file) exists in the directory");
	return 1;
}

#-----------------------------------------------------------
# Method: HasLockFile() 
# Return: EXIT_SUCCESS(1) or EXIT_FAILURE(0)
#
# Checks whether there is a Lock File for this results file
#-----------------------------------------------------------
sub HasLockFile($$)
{
	my ( $fResults, $d ) = @ARG;

	# Logging System
	my $logger = get_logger();

	my $file = sprintf "%s.lock", $fResults;
	$logger->debug("Directory: ", $d);
	$logger->debug("Checking directory for lock file: ", $file);

	if(! -e "$d/$file") {
		# EXIT_FAILURE(0) - Cannot find file
		$logger->debug("Lock file ($file) not found in directory");
		return 0;
	}
	
	# EXIT_SUCCESS (1) - File is Present
	$logger->debug("Lock file ($file) exists in directory");
	return 1;
}

#-----------------------------------------------------------
# Method: CreateLockFile
# Fails if a lock file already exists
#-----------------------------------------------------------
sub CreateLockFile($$)
{
	my ( $fResults, $d ) = @ARG;

	# Logging System
	my $logger = get_logger();

	my $file = sprintf "%s.lock", $fResults;
	$logger->debug("Directory: ", $d);
	$logger->debug("Creating job lock file in directory: ", $file);

	if(-e "$d/$file") {
		# EXIT_FAILURE(0) - File is Present
		$logger->debug("Job Lock file ($file) already exists in the directory ($d)");
		return 0;
	}
	
	system("touch $d/$file");

	# EXIT_SUCCESS(1)
	$logger->debug("Job Lock file ($file) created in working directory");
	return 1;

}

#-----------------------------------------------------------
# Method: RemoveLockFile
#-----------------------------------------------------------
sub RemoveLockFile($$)
{
	my ( $fResults, $d ) = @ARG;

	# Logging System
	my $logger = get_logger();

	my $file = sprintf "%s.lock", $fResults;
	$logger->debug("Directory: ", $d);
	$logger->debug("Removing job lock file from Directory: ", $file);

	if(! -e "$d/$file") {
		# EXIT_FAILURE(0)
		$logger->debug("Job Lock file ($file) not found in the working directory");
		return 0;
	}
	
	# remove the file
	system("rm -rf $d/$file");

	# EXIT_SUCCESS(1)
	$logger->debug("Job Lock file ($file) removed from the working directory");
	return 1;

}


#-----------------------------------------------------------
# Function: GetSequenceOnce
#-----------------------------------------------------------
sub GetSequenceOnce($)
{
	my ($fhDatabase) = @ARG;

	my ($length) = 0;
	my ($sequence) = '';
	
	SEQ: while( my $line = $fhDatabase->getline() ) 
	{
		# '>' signals the end of the sequence
		# i.e. the start of a new sequence
		if ($line =~ /^>/o ) {
			$length = 0 - length( $line );
			seek $fhDatabase, $length, 1;
			last SEQ;
		}
		
		# Handle comment lines
		if ($line =~ /^#/o ) { last SEQ; }

		# Save sequence
		chomp $line;
		$sequence .= $line;		
	}

	# remove windows '\r' characters that may have crept in
	$sequence =~ s/\r//g;

	# remove stop codon characters that may have crept in
	$sequence =~ s/\*//g;

	return $sequence;
}

#--------------------------------------------------------------------
#--------------------------------------------------------------------
package ParameterHelper;
use English;
use strict;

sub new ($)
{
	my ($class) = @ARG;
	my $this = {
		'blast_executable' 	=> '',
		'blast_word_size' 	=> 30,
		'blast_task' 		=> 'blastn',
		'e-value_collect'	=> 10,
		'sequence_identity_collect'	=> 50,
		'number_of_threads_per_job'	=> 1,
		'working_directory'	=> '',
		'warehouse_directory'	=> '',
		'delete_files'		=> 0,
		'counter'		=> 0,
		'total_entries'		=> 0,
		'maximum_query_overlap'	=> 0,
		'minimum_match_coverage' => 0,
		'minimum_match_sequence_identity' => 0,
		'reporting_limit' => 0,
		'identity_calculation_method' => 'local',
		'user_defined_field' => {},

	};
	return bless $this, $class;
}

sub getBlastExecutable($)	{ return $ARG[0]->{'blast_executable'}; }
sub getBlastWordSize($)		{ return $ARG[0]->{'blast_word_size'}; }
sub getBlastTask($)		{ return $ARG[0]->{'blast_task'}; }
sub getEvalueCollect($)		{ return $ARG[0]->{'e-value_collect'}; }
sub getSeqIdCollect($)		{ return $ARG[0]->{'sequence_identity_collect'}; }
sub getNumberOfThreadsPerJob($)	{ return $ARG[0]->{'number_of_threads_per_job'}; }
sub getWorkingDirectory($)	{ return $ARG[0]->{'working_directory'}; }
sub getWarehouseDirectory($)	{ return $ARG[0]->{'warehouse_directory'}; }
sub getCounter($)		{ return $ARG[0]->{'counter'}; }
sub getTotalEntries($)		{ return $ARG[0]->{'total_entries'}; }
sub getMaximumQueryOverlap($)	{ return $ARG[0]->{'maximum_query_overlap'}; }
sub getMinimumMatchCoverage($)	{ return $ARG[0]->{'minimum_match_coverage'}; }
sub getMinimumMatchSequenceIdentity($)	{ return $ARG[0]->{'minimum_match_sequence_identity'}; }
sub getReportingLimit($)	{ return $ARG[0]->{'reporting_limit'}; }
sub getIdentityCalculationMethod($)	{ return $ARG[0]->{'identity_calculation_method'}; }
sub getUserDefinedField($$)	{ return $ARG[0]->{'user_defined_field'}{$ARG[1]}; }

sub setBlastExecutable($$)	{ $ARG[0]->{'blast_executable'} = $ARG[1]; return; }
sub setBlastWordSize($$)	{ $ARG[0]->{'blast_word_size'} = $ARG[1]; return; }
sub setBlastTask($$)		{ $ARG[0]->{'blast_task'} = $ARG[1]; return; }
sub setEvalueCollect($$)	{ $ARG[0]->{'e-value_collect'} = $ARG[1]; return; }
sub setSeqIdCollect($$)		{ $ARG[0]->{'sequence_identity_collect'} = $ARG[1]; return; }
sub setNumberOfThreadsPerJob($$) { $ARG[0]->{'number_of_threads_per_job'} = $ARG[1]; return; }
sub setWorkingDirectory($$)	{ $ARG[0]->{'working_directory'} = $ARG[1]; return; }
sub setWarehouseDirectory($$)	{ $ARG[0]->{'warehouse_directory'} = $ARG[1]; return; }
sub setCounter($$)		{ $ARG[0]->{'counter'} = $ARG[1]; return; }
sub setTotalEntries($$)		{ $ARG[0]->{'total_entries'} = $ARG[1]; return; }
sub setMaximumQueryOverlap($$)	{ $ARG[0]->{'maximum_query_overlap'} = $ARG[1]; return; }
sub setMinimumMatchCoverage($$)	{ $ARG[0]->{'minimum_match_coverage'} = $ARG[1]; return; }
sub setMinimumMatchSequenceIdentity($$)	{ $ARG[0]->{'minimum_match_sequence_identity'} = $ARG[1]; return; }
sub setReportingLimit($$)	{ $ARG[0]->{'reporting_limit'} = $ARG[1]; return; }
sub setIdentityCalculationMethod($$)	{ $ARG[0]->{'identity_calculation_method'} = $ARG[1]; return; }

sub setUserDefinedField($$$)
{
        my ($this, $key, $value) = @ARG;
        $this->{'user_defined_field'}{$key} = $value;
	return;
}

# has methods
sub hasUserDefinedField($$)    { return exists $ARG[0]->{'user_defined_field'}{$ARG[1]} }

sub setToDeleteFiles($)		{ $ARG[0]->{'delete_files'} = 1; return; }
sub setToKeepFiles($)		{ $ARG[0]->{'delete_files'} = 0; return; }
sub deleteFiles($)		{ return $ARG[0]->{'delete_files'}; }

#--------------------------------------------------------------------
# END OF PROGRAM
#--------------------------------------------------------------------

