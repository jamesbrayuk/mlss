#==============================================================================
# MODULE: JTableReader.pm
#==============================
# AUTHOR:  James Bray
# CREATED: 22.03.2021
# UPDATED: ----------
# VERSION: v1.0.0
#
#------------------------------------------------------------------------------
# VERSION HISTORY:
# v1.0.0 (22.03.2021) original
#
#------------------------------------------------------------------------------
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
# DESCRIPTION:
# This module contains one class:
#
# 1. JTableReader class
# 	- Used for reading a table into JTableEntry objects
#	- Requires first line to contain header strings
#
# Reads whole file at once:
# Standard approach:
# Create object and then explicitly call readFile() with the filename
#
# my $oJTableReader = JTableReader->new();
# $oJTableReader->readFile($fTable);
# my $aArray = $oJTableReader->getArray();
#
# Alternatively pass filename to new() and file will be read:
#
# my $oJTableReader = JTableReader->new($fTable);
# my $aArray = $oJTableReader->getArray();
#
#------------------------------------------------------------------------------
# NOTES:
# Will only read the number of fields that are found in the header
#   (will ignore any extra fields in data rows)
#
# Will NOT report header field and data field count inconsistency
#
# Can only pass filename using new() or readFile()
#
#==============================================================================

#==============================================================================
# CLASS: JTableReader
#===========================
# DESCRIPTION:
#
# REQUIRES:
# JTableEntry
#
# AFFILIATIONS:
# None
#
#--------------------------------------------------------------------

#_ Class declaration

package JTableReader;

#_ Include libraries

use strict;
use warnings;
use English '-no_match_vars';
use Carp;
use JTableEntry;
use Log::Log4perl qw(get_logger);
use version; our $VERSION = version->declare('v1.0.0');

#------------------------------------------------------------------------------
# INTERFACE
#-------------------------

#-------------------------
#_ INTERFACE: Constructor
#-------------------------

sub new($;$);
# Constructor
# DESCRIPTION: 
#   If filename is passed to the constructor, the file is read
# ARGUMENTS:
#   1. class
#   2: filename (optional)
# RETURN:
#   1. this

#-------------------------------------
#_ INTERFACE: Public instance methods
#-------------------------------------

#-------------------------
#_ INTERFACE: Get methods
#-------------------------
sub getFileName($);
# METHOD: accessor
# DESCRIPTION: 
#   Reads filename stored in object $this->getFileName();
# ARGUMENTS:
#   1. this
# RETURN:
#   <string> FileName string 

sub getArray($);
# METHOD: accessor
# DESCRIPTION: 
#   Reads all entries in internal array e.g. $this->getArray();
# ARGUMENTS:
#   1. this
# RETURN:
#   <\@ JTableEntry> array of JTableEntry objects 

#---------------------------
#_ INTERFACE: Other methods
#---------------------------
sub readFile($$);
# METHOD: modifier
# DESCRIPTION: 
#   Reads all entries into an internal array of JTableEntry objects
# ARGUMENTS:
#   1. this
#   2. filename
# RETURN:
#   EXIT_SUCCESS(1) or croaks if missing filename

sub isEmptyArray($);
# METHOD: accessor
# DESCRIPTION: 
#   Tests occupancy of internal array of JTableEntry objects
# ARGUMENTS:
#   1. this
# RETURN:
#   1 - array is empty
#   0 - array is not empty 

#------------------------------------------------------------------------------
# IMPLEMENTATION 
#---------------

#------------------------------
#_ IMPLEMENTATION: Constructor
#------------------------------

sub new($;$)
{
	my($class) = $ARG[0];
	my($file) = $ARG[1] || undef;

	my $this = {
		'filename' => q{},
		'array'	=> [],
	};
	bless $this, $class;

	if(defined $file) {
		$this->{'filename'} = $file;
		$this->_ReadFile();
	}

	return $this;
}

#------------------------------------------
#_ IMPLEMENTATION: Public instance methods
#------------------------------------------

#------------------------------
#_ IMPLEMENTATION: Get methods
#------------------------------

sub getFileName($)	{ return $ARG[0]->{'filename'}; }

sub getArray($)
{
	my $this = $ARG[0];

	# Return array of $oJTableEntry objects
	return $this->{'array'};
}

#--------------------------------
#_ IMPLEMENTATION: Other methods
#--------------------------------

sub readFile($$)
{
	my($this) = $ARG[0];
	my($fTable) = $ARG[1];

	# Read file and put information into JTableEntry objects
	# All table rows loaded into array in $this
	$this->{'filename'} = $fTable;

	# _ReadFile will croak if there is a problem
	# Will return EXIT_SUCCESS(1) on completion
	my $rv = _ReadFile( $this );

	# EXIT_SUCCESS(1)
	return $rv;
}

sub isEmptyArray($)
{
	my $aArray = $ARG[0]->{'array'};
	if( scalar( @$aArray ) == 0 ) { return 1; }
	else { return 0; }
}

#------------------------------------------------------------------------------
# IMPLEMENTATION 
#---------------

#_ Private class methods

sub _ReadFile($);
sub _GetColumnIndex($);

#-----------------------------------------------------------
# Function: _ReadFile
#
# Requires table name to be stored in the JTable object
#
# Creates $hColumnIndex - but this is not stored anywhere
# 
# Will croak if no table name
# EXIT_SUCCESS(1) returns 1
#-----------------------------------------------------------
sub _ReadFile($)
{
	my ($this) = @ARG;

	#_ Arrays
	my $aJTableEntries = [];
	#_ Hashes
	my $hColumnIndex = {};
	#_ Others
	my $lineCount = 0;

	#_ Logging system
	my $logger = get_logger();

	# Get filename from $this
	my $fTable = $this->getFileName() || "";
	if($fTable eq "") {
		$logger->fatal("Missing table name - Cannot proceed\n");
		croak();
	}

	# Get hash of column index from first row of table
	$hColumnIndex = _GetColumnIndex($this);

	# extract number of headers
	my $columnCount = scalar( keys %$hColumnIndex );

	# Open input filehandle
	my $fhTable = FileHandle->new( $fTable, "r" ) || die "Cannot open input filehandle";

	# loop through all entries
	LINE: while(my $line = $fhTable->getline)
	{
		chomp $line;
		$line =~ s/\r$//;

		if($line eq "") {
			$logger->debug("Empty line in input file (ignoring completely): $fTable\n");
			next LINE;
		}

		# Skip line 1
		$lineCount++;
		if($lineCount == 1) {
			#$logger->debug("Skipping over header line in table: $fTable\n");
			next LINE;
		}

		# create JTableEntry object
		my $oJTableEntry = JTableEntry->new();

		# Loop through all fields in the data line
		# Modification (-1) to read all fields - including empty fields
		my @flds = split /\t/, $line, -1;
	
		# Changed loop to only read number columns found in the table header
		# ignore any extra fields that might be present in the table that do not have a header string
		foreach my $i ( 0 .. $columnCount-1 )
		{
			# Read column text and column index
			my $columnText = $flds[$i];
			my $columnIndex = $i+1;

			# Get Column Header string from hash table $hColumnIndex
			if(exists $hColumnIndex->{$columnIndex} ) {
				my $columnHeader = $hColumnIndex->{$columnIndex};
			
				# save data in a JTableEntry object
				# as a Field( 'FieldName', 'Value' )
				$oJTableEntry->setField( $columnHeader, $columnText );
			}
			else {
				$logger->fatal("Column Index Not Found: $columnIndex\n");
				croak(); # simple exit for now
			}
		}

		# Save the object in an array
		push @$aJTableEntries, $oJTableEntry;
	}

	# Save array in $this
	$this->{'array'} = $aJTableEntries;

	# EXIT_SUCCESS(1)
	return 1;
}


#-----------------------------------------------------------
# Function: _GetColumnIndex
#
# Only reads the first line of the file (looking for header strings)
# Requires table name to be stored in the JTableReader object
#
# Returns: $hColumnIndex
# 		Key = column number
# 		Value = column text/header
#
# Internally uses $hColumnHeaders to detect duplicate headers
# (causes a fatal error)
#		Key = column text/header
#		Value = column number
#-----------------------------------------------------------
sub _GetColumnIndex($)
{
	my ($this) = @ARG;

	#_ Hashes
	my $hColumnIndex = {};
	my $hColumnHeaders = {};
	#_ Others
	my $lineCount = 0;	

	#_ Logging system
	my $logger = get_logger();

	# Get filename from $this
	my $fTable = $this->getFileName() || "";
	if($fTable eq "") {
		$logger->fatal("Missing table name - Cannot proceed\n");
		croak();
	}

	# Open input filehandle
	my $fhTable = FileHandle->new( $fTable, "r" ) || die "Cannot open input filehandle";

	# Loop through all entries
	LINE: while(my $line = $fhTable->getline)
	{
		chomp $line;
		$line =~ s/\r$//;

		if($line eq "") {
			$logger->info("Empty line in input file (ignoring completely): $fTable\n");
			next LINE;
		}

		# increment line counter
		$lineCount++;

		# Do not grab empty fields (trim off empty fields if present)
		# so do not use split modifier -1
		my @flds = split /\t/, $line;
		foreach my $i ( 0 .. scalar(@flds)-1 )
		{
			my $columnText = $flds[$i];
			my $columnIndex = $i+1;

			# Catch duplicates
			if(exists $hColumnHeaders->{$columnText} ) {
				$logger->fatal("Duplicate entry in table header (cannot proceed): $columnText\n");
				croak(); # simple exit for now
			}

			# Save both hashes
			$hColumnIndex->{ $columnIndex } = $columnText;
			$hColumnHeaders->{ $columnText } = $columnIndex;
		}		

		# Only read first line
		if($lineCount == 1) { last LINE; }
	}

	# only return $hColumnIndex
	return $hColumnIndex;
}

#=============
# END OF CLASS
#==============================================================================

#==============
# END OF MODULE
#==============================================================================
1;
