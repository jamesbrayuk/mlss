#==============================================================================
# MODULE: ProfileTableReader.pm
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
# 1. ProfileTableReader class
# 	- Used for reading a table into Profile objects
#	- Requires first line to contain header strings
#
# Read Profile table 
# Pass filename to readFile()
#
# my $oProfileTableReader = ProfileTableReader->new();
# $oProfileTableReader->setUserDefinedLocusIdentifiers($aLoci);
# if(! $oProfileTableReader->readFile($fTable) ) {
#	$logger->fatal("CANNOT READ PROFILE FILE: ", $fIn); exit;
# }
# my $aArray = $oProfileTableReader->getProfiles();
#
#------------------------------------------------------------------------------
# Order of profile array determined alphabetically by isolate name
# Order of alleles per profile is retained in input order
#
#==============================================================================

#==============================================================================
# CLASS: ProfileTableReader
#===========================
# DESCRIPTION:
#
# REQUIRES:
# Profile (+ Allele)
# JTableReader (+ JTableEntry)
#
# AFFILIATIONS:
# None
#
#--------------------------------------------------------------------

#_ Class declaration

package ProfileTableReader;

#_ Include libraries

use strict;
use warnings;
use English '-no_match_vars';
use Carp;
use Log::Log4perl qw(get_logger);
use version; our $VERSION = version->declare('v1.0.0');
use Profile;
use JTableReader;


#------------------------------------------------------------------------------
# INTERFACE
#-------------------------

#-------------------------
#_ INTERFACE: Constructor
#-------------------------

sub new($);
# Constructor
# ARGUMENTS:
#   class
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
# DESCRIPTION: returns profile table filename
# ARGUMENTS:
#   1. this
# RETURN:
#   <string> FileName string 

sub getProfileIdentifierField($);
# METHOD: reader
# DESCRIPTION: returns profile identifier field ('id' or 'rST')
# ARGUMENTS:
#   1. this
# RETURN:
#   <string> profile identifier field string

sub getProfileFeatureField($);
# METHOD: reader
# DESCRIPTION: returns profile feature field (often 'species')
# ARGUMENTS:
#   1. this
# RETURN:
#   <string> profile feature field string

sub getProfiles($);
# METHOD: reader
# DESCRIPTION: returns all entries in internal array of profile objects
# ARGUMENTS:
#   1. this
# RETURN:
#   <\@ Profile> reference to array of Profile objects 

sub getProfileCount($);
# METHOD: reader
# DESCRIPTION: returns number of profile objects stored in internal array
# ARGUMENTS:
#   1. this
# RETURN:
#   <integer> count of Profile objects

sub getUniqueAlleles($);
# METHOD: reader
# DESCRIPTION: returns array of unique allele identifiers from all profiles 
#   stored in internal profile array
# ARGUMENTS:
#   1. this
# RETURN:
#   <\@> reference to array of allele identifiers

sub getLocusIdentifiers($);
# METHOD: reader
# DESCRIPTION: returns array of locus identifiers
#   (list of identifiers to extract from profile table)
# ARGUMENTS:
#   1. this
# RETURN:
#   <\@> reference to array of locus identifiers

#-------------------------
#_ INTERFACE: Set methods
#-------------------------
sub setProfileIdentifierField($$);
# METHOD: modifier
# DESCRIPTION: sets profile identifier field ('id' or 'rST')
# ARGUMENTS:
#   1. this
#   2. <string> profile identifier field
# RETURN:
#   void

sub setProfileFeatureField($$);
# METHOD: modifier
# DESCRIPTION: sets profile feature field (often 'species')
# ARGUMENTS:
#   1. this
#   2. <string> profile feature field
# RETURN:
#   void

sub setLocusIdentifiers($$);
# METHOD: modifier
# DESCRIPTION: sets array of loci to extract from profile table file
# ARGUMENTS:
#   1. this
#   2. <\@> reference to array of locus identifiers
# RETURN:
#   void

sub setToAcceptPositiveNumericAllelesOnly($);
# METHOD: modifier
# DESCRIPTION: sets module to accept positive number allele indices
#   Will ignore: N, zero, empty, square brackets
# ARGUMENTS:
#   1. this
# RETURN:
#   void

sub setToIgnoreZeroAlleles($);
# METHOD: modifier
# DESCRIPTION: sets module to ignore allele indices equal to zero
# ARGUMENTS:
#   1. this
# RETURN:
#   void

sub setToIgnoreSquareBrackets($);
# METHOD: modifier
# DESCRIPTION: sets module to ignore allele indices containing square brackets
# ARGUMENTS:
#   1. this
# RETURN:
#   void

sub setToIgnoreMissingAlleles($);
# METHOD: modifier
# DESCRIPTION: sets module to ignore allele indices with no value
# ARGUMENTS:
#   1. this
# RETURN:
#   void

sub setToIgnoreParalogousFlags($);
# METHOD: modifier
# DESCRIPTION: sets module to ignore allele indices equal to N
# ARGUMENTS:
#   1. this
# RETURN:
#   void

#---------------------------
#_ INTERFACE: Other methods
#---------------------------
sub readFile($$);
# METHOD: modifier
# DESCRIPTION: reads all entries into an internal array of Profile objects
#   Failure (0): filename is not set
#   Failure (0): no locus identifiers set
#   Failure (0): JTableReader fails to read any line completely
# ARGUMENTS:
#   1. this
#   2. filename
# RETURN:
#   EXIT_SUCCESS(1) or EXIT_FAILURE(0)

sub readZeroAllelesMode($);
# METHOD: reader
# DESCRIPTION: returns zero allele reading mode
# ARGUMENTS:
#   1. this
# RETURN:
#   <boolean>: 1 (read zeros) or 0 (ignore zeros) [default = 1]

sub readSquareBracketMode($);
# METHOD: reader
# DESCRIPTION: returns square bracket allele reading mode
# ARGUMENTS:
#   1. this
# RETURN:
#   <boolean>: 1 (read square brackets) or 0 (ignore square brackets) [default = 1]

sub readMissingAllelesMode($);
# METHOD: reader
# DESCRIPTION: returns missing allele reading mode (empty cell in table)
# ARGUMENTS:
#   1. this
# RETURN:
#   <boolean>: 1 (read missing alleles) or 0 (ignore missing alleles) [default = 1]

sub readParalogousFlagsMode($);
# METHOD: reader
# DESCRIPTION: returns paralogous flag ('N') allele reading mode
# ARGUMENTS:
#   1. this
# RETURN:
#   <boolean>: 1 (read Ns) or 0 (ignore Ns) [default = 1]

sub isEmptyArray($);
# METHOD: reader
# DESCRIPTION: checks internal array of Profile objects
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
		'profiles' => [],
		'locus_identifiers' => [],
		'read_zero_index_alleles' => 1,
		'read_square_brackets' => 1,
		'read_missing_alleles' => 1,
		'read_paralogous_flags' => 1,
		'profile_identifier_field' => 'id',
		'profile_feature_field' => 'species',
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

sub getProfileIdentifierField($)	{ return $ARG[0]->{'profile_identifier_field'}; }

sub getProfileFeatureField($)	{ return $ARG[0]->{'profile_feature_field'}; }

sub getProfiles($) {
	# Return array of $oProfile objects
	return $ARG[0]->{'profiles'};
}

sub getProfileCount($) {
	# Return count of $oProfile objects
	return scalar( @{ $ARG[0]->{'profiles'} } );
}

# extract unique alleles from all profiles
sub getUniqueAlleles($) {
	my $hAlleles = {};
	my $aAlleles = [];
	foreach my $oProfile ( @{ $ARG[0]->{'profiles'} } ) {
		foreach my $oAllele ( @{ $oProfile->getAlleles() } ) {
			if(! exists $hAlleles->{ $oAllele->getAlleleIdentifier() } ) {
				push @$aAlleles, $oAllele;
			}		
		}
	}
	return $aAlleles;
}

sub getLocusIdentifiers($)	{ return $ARG[0]->{'locus_identifiers'}; }

#------------------------------
#_ IMPLEMENTATION: Set methods
#------------------------------

sub setProfileIdentifierField($$) { $ARG[0]->{'profile_identifier_field'} = $ARG[1]; return; }
sub setProfileFeatureField($$) { $ARG[0]->{'profile_feature_field'} = $ARG[1]; return; }
sub setLocusIdentifiers($$) { $ARG[0]->{'locus_identifiers'} = $ARG[1]; return; }

sub setToAcceptPositiveNumericAllelesOnly($) {
	$ARG[0]->{'read_zero_index_alleles'} = 0;
	$ARG[0]->{'read_square_brackets'} = 0;
	$ARG[0]->{'read_missing_alleles'} = 0;
	$ARG[0]->{'read_paralogous_flags'} = 0;
}

sub setToIgnoreZeroAlleles($) 		{ $ARG[0]->{'read_zero_index_alleles'} = 0; }
sub setToIgnoreSquareBrackets($) 	{ $ARG[0]->{'read_square_brackets'} = 0; }
sub setToIgnoreMissingAlleles($) 	{ $ARG[0]->{'read_missing_alleles'} = 0; }
sub setToIgnoreParalogousFlags($) 	{ $ARG[0]->{'read_paralogous_flags'} = 0; }

#--------------------------------
#_ IMPLEMENTATION: Other methods
#--------------------------------

sub readFile($$)
{
	my($this) = $ARG[0];
	my($fTable) = $ARG[1];

	# Read file and put information into Profile objects
	# All table rows loaded into array in $this
	# _ReadFile() will not proceed if there is no file to read and will EXIT_FAILURE(0)
	# if file is read will EXIT_SUCCESS(1)
	$this->{'filename'} = $fTable;
	my $rv = _ReadFile( $this );

	# EXIT_SUCCESS(1) or EXIT_FAILURE(0)
	return $rv;
}

sub readZeroAllelesMode($) 		{ return $ARG[0]->{'read_zero_index_alleles'}; }
sub readSquareBracketMode($) 		{ return $ARG[0]->{'read_square_brackets'}; }
sub readMissingAllelesMode($) 		{ return $ARG[0]->{'read_missing_alleles'}; }
sub readParalogousFlagsMode($) 		{ return $ARG[0]->{'read_paralogous_flags'}; }

sub isEmptyArray($)
{
	my $aProfiles = $ARG[0]->{'profiles'};
	if( scalar( @$aProfiles ) == 0 ) { return 1; }
	else { return 0; }
}


#------------------------------------------------------------------------------
# IMPLEMENTATION 
#---------------

#_ Private class methods

sub _ReadFile($);

#-----------------------------------------------------------
# Function: _ReadFile
#
# Requires table name to be stored in the ProfileTableReader object
# Requires at least one locus in locus array
# Returns EXIT_SUCCESS(1) or EXIT_FAILURE(0)
#   Failure (0): filename is not set
#   Failure (0): no locus identifiers set
#   Failure (0): JTableReader fails to read any line completely
#   Failure (0): one or more loci in locus array is missing from the table
#-----------------------------------------------------------
sub _ReadFile($)
{
	my ($this) = @ARG;

	#_ Logging system
	my $logger = get_logger();

	# Get filename from $this
	my $fTable = $this->getFileName() || "";
	if($fTable eq "") {
		$logger->fatal("Missing table name - Cannot proceed\n");
		return 0; # EXIT_FAILURE
	}

	# Get Locus Identifiers to search for
	my $aLoci = $this->getLocusIdentifiers();
	if(scalar(@$aLoci)==0) {
		$logger->fatal("Missing list of locus identifiers - Cannot proceed\n");
		return 0; # EXIT_FAILURE
	}

	# Read Table
	my $oJTableReader = JTableReader->new();

	# readFile() returns EXIT_SUCCESS(1) or EXIT_FAILURE(0)
	if(! $oJTableReader->readFile($fTable) ) {
		$logger->fatal("Cannot read table\n");
		return 0; # EXIT_FAILURE
	}

	my $aTableEntries = $oJTableReader->getArray();

	# hash of Profiles key: IsolateName value: $oProfile
	my $hProfiles = {};
	# array of Profile objects
	my $aProfiles = [];
	# count the number of isolates
	my $profileCount = 0;

	my $prefix = '';
	my $profileIdentifierField = $this->getProfileIdentifierField();
	if($profileIdentifierField eq 'id') { $prefix = 'ISOLATE_'; }
	elsif($profileIdentifierField eq 'rST') { $prefix = 'RST_'; }
	elsif($profileIdentifierField eq 'ST') { $prefix = 'ST_'; }
	else { $prefix = 'USER-DEFINED_'; }

	my $profileFeatureField = $this->getProfileFeatureField();
	#if($profileFeatureField eq '') {
	#	$logger->fatal("Profile feature field (often 'species') is missing (cannot proceed)");
	#	return 0; # EXIT_FAILURE
	#}

	# Sanity check 
	# Check first row contains id, rST or ST field
	my $oTableEntry = $aTableEntries->[0];
	if($profileIdentifierField eq 'id' && $oTableEntry->hasField('id') == 0) {
		$logger->fatal("Profile identifier field 'id' is missing (cannot proceed)");
		return 0; # EXIT_FAILURE
	}

	if($profileIdentifierField eq 'rST' && $oTableEntry->hasField('rST') == 0) {
		$logger->fatal("Profile identifier field 'rST' is missing (cannot proceed)");
		return 0; # EXIT_FAILURE
	}

	if($profileIdentifierField eq 'ST' && $oTableEntry->hasField('ST') == 0) {
		$logger->fatal("Profile identifier field 'ST' is missing (cannot proceed)");
		return 0; # EXIT_FAILURE
	}

	#---------------------------------------
	# Loop through each table row
	#---------------------------------------
	ENTRY: foreach my $oTableEntry ( @$aTableEntries )
	{
		my $numericIdentifier = '';
		my $profileName = '';

		# Create profile name from value in 'id', 'rST' or 'ST' field
		if( $oTableEntry->hasField('id') && $profileIdentifierField eq 'id' ) {
			$numericIdentifier = $oTableEntry->getField('id');
		}
		elsif( $oTableEntry->hasField('rST') && $profileIdentifierField eq 'rST' ) {
			$numericIdentifier = $oTableEntry->getField('rST');
		}
		elsif( $oTableEntry->hasField('ST') && $profileIdentifierField eq 'ST' ) {
			$numericIdentifier = $oTableEntry->getField('ST');
		}
		else {
			$logger->fatal("Missing 'id', 'rST' or 'ST' field (cannot proceed): $profileCount");
			return 0; # EXIT_FAILURE
		}

		# trim off any white-space
		$numericIdentifier =~ s/^\s+//;
		$numericIdentifier =~ s/\s+$//;
		$profileName = sprintf "%s%s", $prefix, $numericIdentifier;
		$logger->debug("NUMERIC IDENTIFIER: $numericIdentifier");

		# Get Feature information (often species)
		my $feature = 'N/A';
		if( $oTableEntry->hasField($profileFeatureField) ) {
			$feature = $oTableEntry->getField($profileFeatureField);
			if($feature eq '') { $feature = 'N/A'; }
		}

		# Get Isolate identifier information ('isolate' field) - save in profile alias field
		my $alias = 'N/A';
		if( $oTableEntry->hasField('isolate') ) {
			$alias = $oTableEntry->getField('isolate');
			if($alias eq '') { $alias = 'N/A'; }
		}

		# This is a new isolate name - create a new Profile object
		if(! exists $hProfiles->{$numericIdentifier} )
		{
			# create a new Profile object
			my $oProfile = Profile->new();
			$oProfile->setIdentifier($numericIdentifier);
			$oProfile->setName($profileName);
			$oProfile->setAlias($alias);
			$oProfile->setFeature($feature);
			$hProfiles->{$numericIdentifier} = $oProfile;
			#$logger->debug("ISOLATE_NAME [$isolate_counter]: ", $profileName);
		}

		# Get Profile Object
		my $oProfile = $hProfiles->{$numericIdentifier};

		# count missing loci
		my $error = 0;

		#---------------------------------------
		# Loop through each locus
		#---------------------------------------
		foreach my $locusIdentifier ( @$aLoci )
		{
			if($error > 0) {
				$logger->fatal("Missing at least one requested locus (cannot proceed)");
				return 0; # EXIT_FAILURE
			}

			if($oTableEntry->hasField($locusIdentifier) ) {
				my $aAlleleIndices = [];
				my $cellContents = $oTableEntry->getField($locusIdentifier);
				if($cellContents =~ m/;/) {
					@$aAlleleIndices = split /\;/, $cellContents;
				}
				else {
					$aAlleleIndices->[0] = $cellContents;
				}
	
				# loop through all allele indexes in the cell
				ALLELE: foreach my $alleleIndex ( @$aAlleleIndices )
				{
					# trim off white-space
					$alleleIndex =~ s/^\s+//;
					$alleleIndex =~ s/\s+$//;

					# handle zero alleles
					if($alleleIndex eq '0') {
						if(! $this->readZeroAllelesMode() ) { next ALLELE; }
					}

					# handle cells with square brackets
					elsif($alleleIndex =~ m/\]/) {
						if(! $this->readSquareBracketMode() ) { next ALLELE; }
					}

					# handle empty cells
					elsif($alleleIndex eq '') {
						if(! $this->readMissingAllelesMode() ) { next ALLELE; }
					}

					# handle empty cells
					elsif($alleleIndex eq 'N') {
						if(! $this->readParalogousFlagsMode() ) { next ALLELE; }
					}

					# no else statement

					# Create the allele object
					my $oAllele = new Allele;
					$oAllele->setLocusIdentifier( $locusIdentifier );
					$oAllele->setAlleleIndex( $alleleIndex );
					$oProfile->addAllele( $oAllele );
				}
			}
			else {
				$logger->error("LOCUS: $locusIdentifier NOT_FOUND");
				$error++;
			}
		}
	}

	foreach my $numericIdentifier ( sort keys %{$hProfiles} )
	{
		my $oProfile = $hProfiles->{$numericIdentifier};
		push @$aProfiles, $oProfile;
	}

	# Save array in $this
	$this->{'profiles'} = $aProfiles;

	# EXIT_SUCCESS
	return 1;
}

#=============
# END OF CLASS
#==============================================================================

#==============
# END OF MODULE
#==============================================================================
1;
