#==============================================================================
# MODULE: ScanReader.pm
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
#------------------------------------------------------------------------------
# DESCRIPTION:
# This module contains one class:
#
# 1. ScanReader class
# 	- Used for reading files for ScanEntry lines
#
# NOTE: Only stores data in an internal array and generates a hash
#       table on the fly when requested
#
#------------------------------------------------------------------------------
# TYPICAL USAGE:
# 1. Read whole file at once:
#
# my $oScanReader = ScanReader->new();
# $oScanReader->readFile($fIn);
# my $aArray = $oScanReader->getArray($aIdentifiers);
# my $hHash = $oScanReader->getHash($aIdentifiers);
#
#==============================================================================

#==============================================================================
# CLASS: ScanReader
#===========================
# DESCRIPTION:
#
# REQUIRES:
# ScanEntry
#
# AFFILIATIONS:
# None
#
#--------------------------------------------------------------------

#_ Class declaration

package ScanReader;

#_ Include libraries

use strict;
use warnings;
use English '-no_match_vars';
use Carp;
use ScanEntry;
use version; our $VERSION = version->declare('v1.0.0');
use Log::Log4perl qw(get_logger);

#------------------------------------------------------------------------------
# INTERFACE
#-------------------------

#-------------------------
#_ INTERFACE: Constructor
#-------------------------

sub new($);
# Constructor
# ARGUMENTS:
#   1. class
# RETURN:
#   1. this

#-------------------------------------
#_ INTERFACE: Public instance methods
#-------------------------------------

#-------------------------
#_ INTERFACE: Get methods
#-------------------------
sub getFileName($);
# METHOD: reader
# DESCRIPTION: returns filename string
# ARGUMENTS:
#   1. this
# RETURN:
#   <string> filename string

sub getMinimumSimilarity($);
# METHOD: reader
# DESCRIPTION: returns minimum sequence identity for reporting entries
# ARGUMENTS:
#   1. this
# RETURN:
#   <float> sequence identity

sub getArray($);
# METHOD: reader
# DESCRIPTION: reads all entries in internal array e.g. $this->getArray();
# ARGUMENTS:
#   1. this
# RETURN:
#   <\@ ScanEntry> array of ScanEntry objects 

sub getHash($);
# METHOD: reader
# DESCRIPTION: 
#   Reads all entries in internal array e.g. $this->getHash();
# ARGUMENTS:
#   1. this
# RETURN:
#   <\% ScanEntry> hash of ScanEntry objects 
#   Key = Identifiers
#   Value = ScanEntry object

#-------------------------
#_ INTERFACE: Set methods
#-------------------------
sub setMinimumSimilarity($$);
# METHOD: modifier
# DESCRIPTION: set minimum sequence identity for reporting entries
# ARGUMENTS:
#   1. this
#   2. <float> sequence identity
# RETURN:
#   void

#---------------------------
#_ INTERFACE: Other methods
#---------------------------
sub readFile($$);
# METHOD: modifier
# DESCRIPTION: reads all entries into an internal array of ScanThresholdEntry objects
#   Failure (croak): filename is not set
#   Failure (confess): cannot open file for reading
#   Failure (0): ScanEntry fails to read any line
# ARGUMENTS:
#   1. this
#   2. filename
# RETURN:
#   EXIT_SUCCESS(1) or EXIT_FAILURE(0)

sub isEmptyArray($);
# METHOD: reader
# DESCRIPTION: tests occupancy of internal array of ScanEntry objects
# ARGUMENTS:
#   1. this
# RETURN:
#   <boolean>: 1 (array is empty) or 0 (array is not empty)

#------------------------------------------------------------------------------
# IMPLEMENTATION 
#---------------

#------------------------------
#_ IMPLEMENTATION: Constructor
#------------------------------

sub new($)
{
	my($class) = $ARG[0];

	my $this = {
		'filename' => q{},
		'minimum_similarity' => 0,
		'array'	=> [],
	};

	return bless $this, $class;
}

#------------------------------------------
#_ IMPLEMENTATION: Public instance methods
#------------------------------------------

#------------------------------
#_ IMPLEMENTATION: Get methods
#------------------------------

sub getFileName($)	{ return $ARG[0]->{'filename'}; }
sub getMinimumSimilarity($)	{ return $ARG[0]->{'minimum_similarity'}; }

sub getArray($)
{
	my $this = $ARG[0];

	# Return array of $oScanEntry objects or EXIT_FAILURE (0)
	return $this->{'array'};
}

sub getHash($)
{
	my $this = $ARG[0];

	# Return hash of $oScanEntry objects or EXIT_FAILURE (0)
	return $this->_ConvertToHash();
}


#------------------------------
#_ IMPLEMENTATION: Set methods
#------------------------------

sub setMinimumSimilarity($$)	{ $ARG[0]->{'minimum_similarity'} = $ARG[1]; return; }

#--------------------------------
#_ IMPLEMENTATION: Other methods
#--------------------------------

sub readFile($$)
{
	my($this) = $ARG[0];
	my($f) = $ARG[1];
	
	$this->{'filename'} = $f;

	# Read file and put information into JTargetEntry objects
	# All targets loaded into array in $this
	return $this->_ReadAllEntries();
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

sub _ReadAllEntries($);
sub _ConvertToHash($);

#-----------------------------------------------------------
# Function: _ReadAllEntries
#
# Read Scan results file and create internal array of scanEntry objects
#
#-----------------------------------------------------------
sub _ReadAllEntries($)
{
	my ( $this ) = @ARG;

	#_ Hashes
	my ( $hScanEntries ) = {};
	#_ Arrays
	my ( $aScanEntries ) = [];

	#_ Logging system
	my $logger = get_logger();

	my $minimumSimilarity = $this->getMinimumSimilarity();

	# Extract table name
	my $fTable = $this->getFileName();
	if($fTable eq '') {
		$logger->fatal("No filename specified\n");
		croak();
	}

	# Open filehandle for reading
	my $fhTable = FileHandle->new( $fTable, "r" ) || confess "Cannot open input filehandle: $fTable";

	LINE: while(my $line = $fhTable->getline)
	{
		# Skip comment lines and empty lines
		chomp $line;
		if( $line =~ m/^#/ ) { next LINE; }
		if ($line eq "" ) { next LINE; }

		# Create ScanEntry Object
		# ScanEntry::new returns Failure(implicit undef) if cannot parse line
		my $oScanEntry = ScanEntry->new( $line );

		# Catch errors
		if(! defined $oScanEntry) {
			$logger->error("Failed to create ScanEntry\n");
			return 0;
		}

		my $identity = $oScanEntry->getSequenceIdentity();
		if($identity < $minimumSimilarity) {
			#last LINE;
			next LINE;
		}

		push @$aScanEntries, $oScanEntry;
	}
		
	# close output filehandle
	$fhTable->close;

	# create hash and array data structures
	$this->{'array'} = $aScanEntries;

	return 1;
}

#---------------------------------------------------
# Function:  _ConvertToHash
#
# Input:  $this
#
# Output: $hScanEntries - hash of ScanEntry objects
#         or 0 for EXIT_FAILURE
#---------------------------------------------------
sub _ConvertToHash($)
{
	my ( $this )  = @ARG;

	#_ Hashes
	my ( $hScanEntries ) = {};

	#_ Logging system
	my $logger = get_logger();

	foreach my $oScanEntry ( @{ $this->{'array'} } )
	{
		my $identifier = $oScanEntry->getProfileName();
			
		if(! exists $hScanEntries->{ $identifier } ) {
			$hScanEntries->{ $identifier } = $oScanEntry;
		}
		else {
			$logger->error("Duplicate Query: $identifier");
		}
	}

	return $hScanEntries;
}

#=============
# END OF CLASS
#==============================================================================

#==============
# END OF MODULE
#==============================================================================
1;
