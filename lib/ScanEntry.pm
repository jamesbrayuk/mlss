#==============================================================================
# MODULE: ScanEntry.pm
#==============================
# AUTHOR:  James Bray
# CREATED: 22.03.2021
# UPDATED: ----------
# VERSION: v1.0.0
#
#------------------------------------------------------------------------------
# VERSION HISTORY:
# v1.0.0 (22.03.2021) original version
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
# ScanEntry class.
# 	- Used for encapsulating a single line of a SCAN RESULTS file
#
#------------------------------------------------------------------------------
# SCAN FILE FORMAT 2.2 (13 columns)
# Tab separated format:
# Column 1: Rank Number
# Column 2: Contigs Filename
# Column 3: Profile Name (string)
# Column 4: Sequence Identity (%)
# Column 5: Profile Feature (string)
# Column 6: Traffic Light Colour
# Column 7: Nucleotide Overlap (%)
# Column 8: Matched Allele Count / Profile Allele Count
# Column 9: Number of Identical Matches / Sequence Identity Denominator*
# Column 10: Matched Nucleotide Count / Profile Nucleotide Count
# Column 11: Total Blast Score
# Column 12: Profile Numeric Identifier
# Column 13: Identity Calculation Method
#
# *NOTE: Sequence Identity Denominator depends on the identity calculation method
# global = Profile Nucleotide Count, local = Matched Nucleotide Count
#
#==============================================================================

#==============================================================================
# CLASS: ScanEntry
#==========================
# DESCRIPTION:
# Used for encapsulating a single line of a SCAN file
#
# AFFILIATIONS:
# None
#
#---------------------------------------------------------------------------------

#_ Class declaration

package ScanEntry;

#_ Include libraries

use strict;
use warnings;
use English '-no_match_vars';
use Log::Log4perl qw(get_logger);
use version; our $VERSION = version->declare('v1.0.0');
use File::Basename;

#------------------------------------------------------------------------------
# INTERFACE
#----------

#-------------------------
#_ INTERFACE: Constructor
#-------------------------

sub new($;$);
# Constructor
# ARGUMENTS:
#   1. class
#   2. <string> [optional] line
# RETURN:
#   1. this
#   OR Failure(implicit undef): if line passed AND failed to read line

#-------------------------------------
#_ INTERFACE: Public instance methods
#-------------------------------------

#-------------------------
#_ INTERFACE: Get methods
#-------------------------
sub getRankNumber($);
# METHOD: reader
# DESCRIPTION: returns rank number
# ARGUMENTS:
#   1. this
# RETURN:
#   <integer> rank number

sub getContigsFilename($);
# METHOD: reader
# DESCRIPTION: returns contigs filename (may include full path)
# ARGUMENTS:
#   1. this
# RETURN:
#   <string> contigs filename string 

sub getProfileName($);
# METHOD: reader
# DESCRIPTION: returns profile name (string)
# ARGUMENTS:
#   1. this
# RETURN:
#   <string> profile name

sub getSequenceIdentity($);
# METHOD: reader
# DESCRIPTION: returns sequence identity (%)
# ARGUMENTS:
#   1. this
# RETURN:
#   <float> sequence identity (%)

sub getProfileFeature($);
# METHOD: reader
# DESCRIPTION: returns profile feature string (often species)
# ARGUMENTS:
#   1. this
# RETURN:
#   <string> profile feature

sub getTrafficLightColour($);
# METHOD: reader
# DESCRIPTION: returns traffic light colour (Green, Amber, Red, N/A)
# ARGUMENTS:
#   1. this
# RETURN:
#   <string> traffic light colour

sub getNucleotideOverlap($);
# METHOD: reader
# DESCRIPTION: returns sequence identity (%)
# ARGUMENTS:
#   1. this
# RETURN:
#   <float> sequence identity (%)

sub getMatchedAlleleCount($);
# METHOD: reader
# DESCRIPTION: returns number of matched alleles
# ARGUMENTS:
#   1. this
# RETURN:
#   <integer> matched allele count

sub getProfileAlleleCount($);
# METHOD: reader
# DESCRIPTION: returns total number of alleles in the profile
# ARGUMENTS:
#   1. this
# RETURN:
#   <integer> profile allele count

sub getIdenticalNucleotideCount($);
# METHOD: reader
# DESCRIPTION: returns number of identical nucleotides in all query-target alignments
# ARGUMENTS:
#   1. this
# RETURN:
#   <integer> identical nucleotide count

sub getMatchedNucleotideCount($);
# METHOD: reader
# DESCRIPTION: returns total number of nucleotides in all query-target alignments
# ARGUMENTS:
#   1. this
# RETURN:
#   <integer> matched nucleotide count

sub getProfileNucleotideCount($);
# METHOD: reader
# DESCRIPTION: returns total number of nucleotides in all profile alleles
# ARGUMENTS:
#   1. this
# RETURN:
#   <integer> profile nucleotide count

sub getProfilesFilename($);
# METHOD: reader
# DESCRIPTION: returns profile table filename (may include full path)
# ARGUMENTS:
#   1. this
# RETURN:
#   <string> profile table filename

sub getTotalBlastScore($);
# METHOD: reader
# DESCRIPTION: returns total BLAST raw score (sum across all alignments)
# ARGUMENTS:
#   1. this
# RETURN:
#   <integer> total BLAST raw score

sub getProfileNumericIdentifier($);
# METHOD: reader
# DESCRIPTION: returns profile identifier
# ARGUMENTS:
#   1. this
# RETURN:
#   <integer> profile numeric identifier

sub getSequenceIdentityDenominator($);
# METHOD: reader
# DESCRIPTION: returns sequence identity fraction denominator
#   value varies depending on the identity calculation method
# ARGUMENTS:
#   1. this
# RETURN:
#   <integer> nucleotide count

sub getUserDefinedField($$);
# METHOD: reader
# DESCRIPTION: returns value stored for a user-defined field identifier
#   used in conjunction with hasUserDefinedField()
# ARGUMENTS:
#   1. this
#   2. <string> field identifier
# RETURN:
#   <string> value stored for user-defined field identifier

sub getContigsBasename($);
# METHOD: reader
# DESCRIPTION: returns basename of contigs filename (string after final '/' in path)
# ARGUMENTS:
#   1. this
# RETURN:
#   <string> basename of contigs filename

sub getProfilesBasename($);
# METHOD: reader
# DESCRIPTION: returns basename of profile table filename (string after final '/' in path)
# ARGUMENTS:
#   1. this
# RETURN:
#   <string> basename of profile table filename


#-------------------------
#_ INTERFACE: Set methods
#-------------------------
sub setRankNumber($$);
# METHOD: modifier
# DESCRIPTION: sets rank number
# ARGUMENTS:
#   1. this
#   2. <integer> rank number
# RETURN:
#   void

sub setContigsFilename($$);
# METHOD: modifier
# DESCRIPTION: sets contigs filename (may contain full path)
# ARGUMENTS:
#   1. this
#   2. <string> contigs filename
# RETURN:
#   void

sub setProfileName($$);
# METHOD: modifier
# DESCRIPTION: sets profile name (string)
# ARGUMENTS:
#   1. this
#   2. <string> profile name
# RETURN:
#   void

sub setSequenceIdentity($$);
# METHOD: modifier
# DESCRIPTION: sets sequence identity (%)
# ARGUMENTS:
#   1. this
#   2. <float> sequence identity (%)
# RETURN:
#   void

sub setProfileFeature($$);
# METHOD: modifier
# DESCRIPTION: sets profile species string (binomial)
# ARGUMENTS:
#   1. this
#   2. <string> profile species
# RETURN:
#   void

sub setTrafficLightColour($$);
# METHOD: modifier
# DESCRIPTION: sets traffic light colour (Green, Amber, Red, N/A)
# ARGUMENTS:
#   1. this
#   2. <string> traffic light colour
# RETURN:
#   void

sub setNucleotideOverlap($$);
# METHOD: modifier
# DESCRIPTION: sets total nucleotide overlap (%) across all query-target alignments
# ARGUMENTS:
#   1. this
#   2. <float> overlap (%)
# RETURN:
#   void

sub setMatchedAlleleCount($$);
# METHOD: modifier
# DESCRIPTION: returns number of matched alleles
# ARGUMENTS:
#   1. this
#   2. <integer> matched allele count
# RETURN:
#   void

sub setProfileAlleleCount($$);
# METHOD: modifier
# DESCRIPTION: returns total number of alleles in the profile
# ARGUMENTS:
#   1. this
#   2. <integer> profile allele count
# RETURN:
#   void

sub setIdenticalNucleotideCount($$);
# METHOD: modifier
# DESCRIPTION: sets number of identical nucleotides in all query-target alignments
# ARGUMENTS:
#   1. this
#   2. <integer> identical nucleotide count
# RETURN:
#   void

sub setMatchedNucleotideCount($$);
# METHOD: modifier
# DESCRIPTION: sets total number of nucleotides in all query-target alignments
# ARGUMENTS:
#   1. this
#   2. <integer> number of nucleotides
# RETURN:
#   void

sub setProfileNucleotideCount($$);
# METHOD: modifier
# DESCRIPTION: sets total number of nucleotides in all profile alleles
# ARGUMENTS:
#   1. this
#   2. <integer> profile nucleotide count
# RETURN:
#   void

sub setProfilesFilename($$);
# METHOD: modifier
# DESCRIPTION: sets profile table filename (may contain full path)
# ARGUMENTS:
#   1. this
#   2. <string> profile table filename
# RETURN:
#   void

sub setTotalBlastScore($$);
# METHOD: modifier
# DESCRIPTION: sets total BLAST raw score (sum across all alignments)
# ARGUMENTS:
#   1. this
#   2. <integer> total BLAST raw score
# RETURN:
#   void

sub setProfileNumericIdentifier($$);
# METHOD: modifier
# DESCRIPTION: sets profile numeric identifier
# ARGUMENTS:
#   1. this
#   2. <integer> profile numeric identifier
# RETURN:
#   void

sub setSequenceIdentityDenominator($$);
# METHOD: modifier
# DESCRIPTION: sets sequence identity fraction denominator
#   value varies depending on the identity calculation method
# ARGUMENTS:
#   1. this
#   2. <integer> nucleotide count
# RETURN:
#   void

sub setUserDefinedField($$$);
# METHOD: modifier
# DESCRIPTION: sets user-defined field value associated with a field identifier
# ARGUMENTS:
#   1. this
#   2. <string> field identifier string
#   3. <string> field value
# RETURN:
#   void

#---------------------------
#_ INTERFACE: Other methods
#---------------------------
sub hasUserDefinedField($$);
# METHOD: reader
# DESCRIPTION: checks for user-defined field identifier present in object
# ARGUMENTS:
#   1. this
#   2. <string> field identifier
# RETURN:
#   true or false (from exists)

#------------------------------------------------------------------------------
# IMPLEMENTATION 
#---------------

#_ Constructor

sub new($;$)
{
        my ($class) = $ARG[0];
        my ($line) = $ARG[1] || undef;

        my $this = {
                'rank_number' => 0,
                'contigs_filename' => 'N/A',
                'profile_name' => 'N/A',
		'traffic_light_colour' => 'N/A',
		'profile_feature' => 'N/A',
		'sequence_identity' => 0,
                'nucleotide_overlap' => 0,
                'matched_allele_count' => 0,
                'profile_allele_count' => 0,
		'identical_nucleotide_count' => 0,
                'matched_nucleotide_count' => 0,
                'profile_nucleotide_count' => 0,
                'profiles_filename' => 'N/A',
                'total_blast_score' => 0,
                'profile_numeric_identifier' => 0,
		'identity_calculation_method' => 'global',
		'sequence_identity_denominator' => 0,
		'user_defined_field' => {},

	};

        bless $this, $class;

	# Read the line
	if(defined $line) {
		# Problem reading line returns EXIT_FAILURE(0)
		# As caller wants an object, return implicit undef
		if(! _ReadLine($this, $line) ) { return; }
		else { return $this; } 
	}
	# Return ScanEntry object
	else { return $this; }
}

# get methods
sub getRankNumber($)			{ return $ARG[0]->{'rank_number'}; }
sub getContigsFilename($)		{ return $ARG[0]->{'contigs_filename'}; }
sub getProfileName($)			{ return $ARG[0]->{'profile_name'}; }
sub getSequenceIdentity($)		{ return $ARG[0]->{'sequence_identity'}; }
sub getProfileFeature($)		{ return $ARG[0]->{'profile_feature'}; }
sub getTrafficLightColour($)		{ return $ARG[0]->{'traffic_light_colour'}; }
sub getNucleotideOverlap($)		{ return $ARG[0]->{'nucleotide_overlap'}; }
sub getMatchedAlleleCount($)		{ return $ARG[0]->{'matched_allele_count'}; }
sub getProfileAlleleCount($)		{ return $ARG[0]->{'profile_allele_count'}; }
sub getIdenticalNucleotideCount($)	{ return $ARG[0]->{'identical_nucleotide_count'}; }
sub getMatchedNucleotideCount($)	{ return $ARG[0]->{'matched_nucleotide_count'}; }
sub getProfileNucleotideCount($)	{ return $ARG[0]->{'profile_nucleotide_count'}; }
sub getProfilesFilename($)		{ return $ARG[0]->{'profiles_filename'}; }
sub getTotalBlastScore($)		{ return $ARG[0]->{'total_blast_score'}; }
sub getProfileNumericIdentifier($)	{ return $ARG[0]->{'profile_numeric_identifier'}; }
sub getIdentityCalculationMethod($)	{ return $ARG[0]->{'identity_calculation_method'}; }
sub getSequenceIdentityDenominator($)	{ return $ARG[0]->{'sequence_identity_denominator'}; }

sub getUserDefinedField($$)		{ return $ARG[0]->{'user_defined_field'}{$ARG[1]}; }

sub getContigsBasename($)		{ return basename( $ARG[0]->{'contigs_filename'} ); }
sub getProfilesBasename($)		{ return basename( $ARG[0]->{'profiles_filename'} ); }

# set methods
sub setRankNumber($$)			{ $ARG[0]->{'rank_number'} = $ARG[1]; return; }
sub setContigsFilename($$)		{ $ARG[0]->{'contigs_filename'} = $ARG[1]; return; }
sub setProfileName($$)			{ $ARG[0]->{'profile_name'} = $ARG[1]; return; }
sub setSequenceIdentity($$)		{ $ARG[0]->{'sequence_identity'} = $ARG[1]; return; }
sub setProfileFeature($$)		{ $ARG[0]->{'profile_feature'} = $ARG[1]; return; }
sub setTrafficLightColour($$)		{ $ARG[0]->{'traffic_light_colour'} = $ARG[1]; return; }
sub setNucleotideOverlap($$)		{ $ARG[0]->{'nucleotide_overlap'} = $ARG[1]; return; }
sub setMatchedAlleleCount($$)		{ $ARG[0]->{'matched_allele_count'} = $ARG[1]; return; }
sub setProfileAlleleCount($$)		{ $ARG[0]->{'profile_allele_count'} = $ARG[1]; return; }
sub setIdenticalNucleotideCount($$)	{ $ARG[0]->{'identical_nucleotide_count'} = $ARG[1]; return; }
sub setMatchedNucleotideCount($$)	{ $ARG[0]->{'matched_nucleotide_count'} = $ARG[1]; return; }
sub setProfileNucleotideCount($$)	{ $ARG[0]->{'profile_nucleotide_count'} = $ARG[1]; return; }
sub setProfilesFilename($$)		{ $ARG[0]->{'profiles_filename'} = $ARG[1]; return; }
sub setTotalBlastScore($$)		{ $ARG[0]->{'total_blast_score'} = $ARG[1]; return; }
sub setProfileNumericIdentifier($$)	{ $ARG[0]->{'profile_numeric_identifier'} = $ARG[1]; return; }
sub setIdentityCalculationMethod($$)	{ $ARG[0]->{'identity_calculation_method'} = $ARG[1]; return; }
sub setSequenceIdentityDenominator($$)	{ $ARG[0]->{'sequence_identity_denominator'} = $ARG[1]; return; }

sub setUserDefinedField($$$)
{
        my ($this, $key, $value) = @ARG;
        $this->{'user_defined_field'}{$key} = $value;
	return;
}


# has methods
sub hasUserDefinedField($$)    { return exists $ARG[0]->{'user_defined_field'}{$ARG[1]} }

#------------------------------------------------------------------------------
# IMPLEMENTATION 
#---------------

#_ Private class methods

sub _ReadLine($$);

#-----------------------------------------------------------
# Function: _ReadLine
#
# Reads tab separated file and populates the object
# Failure: line does not contain correct number of fields
#
# Returns: EXIT_SUCCESS(1) or EXIT_FAILURE(0)
#
#-----------------------------------------------------------
sub _ReadLine($$)
{
	my ( $this, $line ) = @ARG;

	my @flds;
	# logging system
	my $logger = get_logger();

	chomp $line;
	$line =~ s/^\s+//;
	@flds = split /\t/, $line;

	# FORMAT 2.2 = 13 columns
	if(scalar(@flds) != 13 ) {
		$logger->error("Number of fields (require 13): ", scalar(@flds) );
		$logger->error("Parse Error ScanEntry line: $line");
		# Return EXIT_FAILURE(0)
		return 0;
	}

	$this->setRankNumber($flds[0]);
	$this->setContigsFilename($flds[1]);
	$this->setProfileName($flds[2]);
	#$this->setSequenceIdentity($flds[3]); # calculate from $flds[8]
	$this->setProfileFeature($flds[4]);
	$this->setTrafficLightColour($flds[5]);
	#$this->setNucleotideOverlap($flds[6]); # calculate from $flds[9]

	my $alleleCountFraction = $flds[7];
	my $identicalNucleotideFraction = $flds[8];
	my $matchedNucleotideFraction = $flds[9];

	# Allele Count Fraction
	my (@fraction1) = split /\//, $alleleCountFraction;
	$this->setMatchedAlleleCount($fraction1[0]);
	$this->setProfileAlleleCount($fraction1[1]);

	# Sequence Identity Fraction - Display
	# If(method=global) numerator = IdenticalNucleotideCount [A]; denominator = ProfileNucleotideCount [C]
	# If(method=local) numerator = IdenticalNucleotideCount [A]; denominator = MatchedNucleotideCount [B]
	my (@fraction2) = split /\//, $identicalNucleotideFraction;
	# identical nucleotide count [A] is always the sequence identity denominator
	$this->setIdenticalNucleotideCount($fraction2[0]);
	$this->setSequenceIdentityDenominator($fraction2[1]);

	# Overlap Fraction
	# matched nucleotide count [B] is always the overlap numerator
	# profile nucleotide count [C] is always the overlap denominator
	my (@fraction3) = split /\//, $matchedNucleotideFraction;
	$this->setMatchedNucleotideCount($fraction3[0]);
	$this->setProfileNucleotideCount($fraction3[1]); 

	# calculate sequence identity & set value
	# Protect against division by zero
	my $sequenceIdentity = 0;
	if($this->getProfileNucleotideCount() != 0) { 
		$sequenceIdentity = 100 * 
		$this->getIdenticalNucleotideCount() / $this->getSequenceIdentityDenominator();
	}
	$this->setSequenceIdentity($sequenceIdentity);

	# Calculate nucleotide overlap & set value
	# Protect against division by zero
	my $nucleotideOverlap = 0;
	if($this->getProfileNucleotideCount() != 0) { 
		$nucleotideOverlap = 100 * $this->getMatchedNucleotideCount() / $this->getProfileNucleotideCount();
	}
	$this->setNucleotideOverlap($nucleotideOverlap);

	# Set additional information
	$this->setTotalBlastScore($flds[10]);
	$this->setProfileNumericIdentifier($flds[11]);
	$this->setIdentityCalculationMethod($flds[12]);

	# Return EXIT_SUCCESS(1)
	return 1;
}

#=============
# END OF CLASS
#==============================================================================

#==============
# END OF MODULE
#==============================================================================
1;
