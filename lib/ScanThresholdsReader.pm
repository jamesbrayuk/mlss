#==============================================================================
# MODULE: ScanThresholdsReader.pm
#================================
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
# 1. ScanThresholdsReader class
# 	- Used for reading a file of ScanThresholds entries
#
# NOTE: Only stores data in an internal array and generates a hash
#       table on the fly when requested
#
#------------------------------------------------------------------------------
# TYPICAL USAGE:
# 1. Read whole file at once:
#
# my $oScanThresholdsReader = ScanThresholdsReader->new();
# $oScanThresholdsReader->readFile( $fIn );
# my $aIdentifiers = ['ISOLATE_2', 'ISOLATE_3']
# my $aArray = $oScanThresholdsReader->getArray($aIdentifiers);
# my $hHash = $oScanThresholdsReader->getHash($aIdentifiers);
#
#------------------------------------------------------------------------------
# FILE FORMAT FOR SCAN THRESHOLDS:
# See ScanThresholdsEntry for file format documentation
# This module is file format independent
#
#==============================================================================

#==============================================================================
# CLASS: ScanThresholdsReader
#===========================
# DESCRIPTION:
#
# REQUIRES:
# ScanThresholdsEntry
#
# AFFILIATIONS:
# None
#
#--------------------------------------------------------------------

#_ Class declaration

package ScanThresholdsReader;

#_ Include libraries

use strict;
use warnings;
use English '-no_match_vars';
use Carp;
use Log::Log4perl qw(get_logger);
use version; our $VERSION = version->declare('v1.0.0');
use ScanThresholdsEntry;

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
# DESCRIPTION: returns filename
# ARGUMENTS:
#   1. this
# RETURN:
#   <string> filename string

sub getArray($;$);
# METHOD: reader
# DESCRIPTION: reads all entries in internal array e.g. $this->getArray();
#   or reads specific entries (as given in array of Identifiers) e.g. $this->getArray($aIdentifiers)
# ARGUMENTS:
#   1. this
#   2. <\@> reference to array of Identifiers - optional
# RETURN:
#   <\@ ScanThresholdsEntry> reference to array of ScanThresholdsEntry objects 

sub getHash($;$);
# METHOD: reader
# DESCRIPTION: reads all entries in internal array e.g. $this->getHash();
#   or reads specific entries (as given in array of Identifiers) e.g. $this->getHash($aIdentifiers)
#   Converts array to a hash table
# ARGUMENTS:
#   1. this
#   2. <\@> reference to array of Identifiers - optional
# RETURN:
#   <\% ScanThresholds> reference to hash of ScanThresholdsEntry objects 
#   Key = Identifier
#   Value = ScanThresholdsEntry object

#---------------------------
#_ INTERFACE: Other methods
#---------------------------
sub readFile($$);
# METHOD: modifier
# DESCRIPTION: reads all entries into an internal array of ScanThresholdEntry objects
#   Failure (croak): filename is not set
#   Failure (confess): cannot open file for reading
#   Failure (0): ScanThresholdsEntry fails to read any line
# ARGUMENTS:
#   1. this
#   2. filename
# RETURN:
#   EXIT_SUCCESS(1) or EXIT_FAILURE(0)

sub isEmptyArray($);
# METHOD: reader
# DESCRIPTION: tests occupancy of internal array of JTableEntry objects
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
		'array'	=> [],
	};
	bless $this, $class;

	return $this;
}

#------------------------------------------
#_ IMPLEMENTATION: Public instance methods
#------------------------------------------

#------------------------------
#_ IMPLEMENTATION: Get methods
#------------------------------

sub getFileName($)	{ return $ARG[0]->{'filename'}; }

sub getArray($;$)
{
	my $this = $ARG[0];
	my $aIdentifiers = $ARG[1] || undef;

	# Return array of $oScanThresholds objects or EXIT_FAILURE (0)
	if(defined($aIdentifiers) ) { return _ExtractEntries( $this, $aIdentifiers, 'ARRAY' ); }
	else { return $this->{'array'}; }
}

sub getHash($;$)
{
	my $this = $ARG[0];
	my $aIdentifiers = $ARG[1] || undef;

	# Return hash of $oScanThresholds objects or EXIT_FAILURE (0)
	if(defined($aIdentifiers) ) { return _ExtractEntries( $this, $aIdentifiers, 'HASH' ); }
	else { return _ConvertToHash( $this ); }
}

#--------------------------------
#_ IMPLEMENTATION: Other methods
#--------------------------------

sub readFile($$)
{
	my ($this) = $ARG[0];
	my ($filename) = $ARG[1];
	
	$this->{'filename'} = $filename;

	# return EXIT_SUCCESS(1) or EXIT_FAILURE(0)
	my $rv = _ReadAllEntries( $this );
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

sub _ReadAllEntries($);
sub _ExtractEntries($$$);
sub _ConvertToHash($);

#-----------------------------------------------------------
# Function: _ReadAllEntries
#
# Read Scan Thresholds file (entirely) and create array of $oScanThresholdsEntry objects
# Reports duplicate identifiers (only saves the first occurrence)
#
# Failure (croak): filename is not set
# Failure (confess): cannot open file for reading
# Failure (0): ScanThresholdsEntry fails to read any line
#
# Success(1)
#-----------------------------------------------------------
sub _ReadAllEntries($)
{
	my ( $this ) = @ARG;

	#_ Hashes
	my ( $hScanThresholdsEntries ) = {};
	#_ Arrays
	my ( $aScanThresholdsEntries ) = [];

	#_ Logging system
	my $logger = get_logger();

	# Extract table name
	my $fTable = $this->getFileName();
	if($fTable eq '') {
		$logger->fatal("No filename specified\n");
		# croak on failure
		croak();
	}

	# Open filehandle for reading
	my $fhTable = FileHandle->new( $fTable, "r" ) || confess "Cannot open input filehandle: $fTable";

	LINE: while(my $line = $fhTable->getline)
	{
		# remove Windows characters
		$line =~ s/\r//g;

		# Skip comment lines and empty lines
		if( $line =~ m/^#/ ) { next LINE; }
		if ($line =~ m/^$/ ) { next LINE; }

		# Create ScanThresholdsEntry Object
		# ScanThresholdsEntry->new returns implicit 'undef' if cannot parse line 
		my $oScanThresholdsEntry = ScanThresholdsEntry->new( $line );

		# Catch errors
		if(! $oScanThresholdsEntry) {
			$logger->error("Failed to create ScanThresholdsEntry for LINE: $line");
			return 0;
		}

		my $identifier = $oScanThresholdsEntry->getIdentifier();
		
		# Save object in hash table and array
		if(! exists $hScanThresholdsEntries->{ $identifier } )
		{
			$hScanThresholdsEntries->{ $identifier } = $oScanThresholdsEntry;
			push @$aScanThresholdsEntries, $oScanThresholdsEntry;
		}
		else {
			$logger->error("Duplicate Identifier: *$identifier*");
		}
	}
		
	# close output filehandle
	$fhTable->close;

	# Save array data structure only
	$this->{'array'} = $aScanThresholdsEntries;

	# EXIT_SUCCESS
	return 1;
}

#---------------------------------------------------
# Function:  _ExtractEntries
#
# Input:  $this
# Input:  $aIdentifiers
# Input:  FLAG for Output format = ARRAY or HASH
#
# Output: $aScanThresholdsEntries - array of ScanThresholds objects
#         OR $hScanThresholdsEntries - hash of ScanThresholds objects
#         OR exits program
#
# Reads specific entries in the THRESHOLDS File
# Reports duplicate identifiers in input array
#---------------------------------------------------
sub _ExtractEntries($$$)
{
	my ( $this, $aIdentifiers, $output_option )  = @ARG;

	#_ Hashes
	my ( $hIdentifiers ) = {};
	my ( $hScanThresholdsEntries ) = {};
	#_ Arrays
	my ( $aScanThresholdsEntries ) = [];
	#_ Objects
	my ( $oScanThresholdsEntry );
	#_ Others
	my ( $identifier );
	#_ Logging system
	my $logger = get_logger();

	# Create hash - ignore duplicates
	foreach $identifier ( @$aIdentifiers )
	{
		if(! exists $hIdentifiers->{$identifier}) { $hIdentifiers->{$identifier} = $identifier; }
	}
	
	foreach $oScanThresholdsEntry ( @{ $this->{'array'} } )
	{
		$identifier = $oScanThresholdsEntry->getIdentifier();
			
		# Only read objects with a specified name
		if( exists $hIdentifiers->{ $identifier } )
		{
			push @$aScanThresholdsEntries, $oScanThresholdsEntry;
			
			if(! exists $hScanThresholdsEntries->{ $identifier } ) {
				$hScanThresholdsEntries->{ $identifier } = $oScanThresholdsEntry;
			}
			else {
				$logger->error("Duplicate Identifier: $identifier");
			}
		}
	}

	if($output_option eq 'ARRAY') { return $aScanThresholdsEntries; }
	elsif($output_option eq 'HASH') { return $hScanThresholdsEntries; }
	else { $logger->fatal("Incorrect output option (must be 'ARRAY' or 'HASH'): $output_option"); exit; }
}


#---------------------------------------------------
# Function:  _ConvertToHash
#
# Input:  $this
#
# Output: $hEntries - hash of ScanThresholdsEntry objects
#         or empty hash table
#
# Reports duplicate identifiers in internal array of objects
#---------------------------------------------------
sub _ConvertToHash($)
{
	my ( $this )  = @ARG;

	#_ Hashes
	my ( $hEntries ) = {};

	#_ Logging system
	my $logger = get_logger();

	foreach my $oScanThresholdsEntry ( @{ $this->{'array'} } )
	{
		my $identifier = $oScanThresholdsEntry->getIdentifier();
			
		if(! exists $hEntries->{ $identifier } ) {
			$hEntries->{ $identifier } = $oScanThresholdsEntry;
		}
		else {
			$logger->error("Duplicate Identifier: $identifier");
		}
	}

	return $hEntries;
}

#=============
# END OF CLASS
#==============================================================================


#==============
# END OF MODULE
#==============================================================================
1;
