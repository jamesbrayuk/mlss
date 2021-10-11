#==============================================================================
# MODULE: ScanThresholdsEntry.pm
#===============================
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
# ScanThresholdsEntry class.
# 	- Used for encapsulating a single entry of a ScanThresholds entry
#
#------------------------------------------------------------------------------
# FILE FORMAT:
# Uses SEVEN columnn Scan Thresholds Format (tab separated):
#
# Column 1: Profile Identifier (e.g. ISOLATE_1 or RST_1)
# Column 2: Threshold A (range 0-100)
# Column 3: Threshold A fraction (number/number, default: 0/0)
# Column 4: Threshold B (range 0-100)
# Column 5: Threshold B fraction (number/number, default: 0/0)
# Column 6: Feature (string)
# Column 7: Comments (default: N/A)
#
# PARSING INFORMATION:
# If the threshold fraction is present from observed data (ie. is not 0/0) the threshold is 
# internally re-calculated from the fraction to avoid using a number that has been 
# rounded up/down in the traffic light colour calculation.
#
# Example line (from observed data):
# ISOLATE_23	98.84958	20622/20862	98.17371	20481/20862	Klebsiella aerogenes	N/A
# 
# Example line (generic values):
# ISOLATE_8556	99.95000	0/0	99.75000	0/0	Klebsiella africana	N/A
# 
# Exception:
# A fraction can be given as '0/0' (e.g. a generic threshold where the bases have not been analysed)
# and then the sequence identity is not recalculated from the fraction and is taken from the
# threshold column (exactly as in the file).
#
#==============================================================================

#==============================================================================
# CLASS: ScanThresholdsEntry
#===========================
# DESCRIPTION:
# Class for encapsulating a single entry of ScanThresholds Entry
#
# AFFILIATIONS:
# None
#
#---------------------------------------------------------------------------------

#_ Class declaration

package ScanThresholdsEntry;

#_ Include libraries

use strict;
use warnings;
use English '-no_match_vars';
use Log::Log4perl qw(get_logger);
use version; our $VERSION = version->declare('v1.0.0');

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
#   2. line [optional]
# RETURN:
#   1. this
#   OR Failure(implicit undef): if line passed AND failed to read line

#-------------------------------------
#_ INTERFACE: Public instance methods
#-------------------------------------

#-------------------------
#_ INTERFACE: Get methods
#-------------------------
sub getIdentifier($);
# METHOD: reader
# DESCRIPTION: returns profile identifier
# ARGUMENTS:
#   1. this
# RETURN:
#   <string> profile identifier string 

sub getThresholdA($);
# METHOD: reader
# DESCRIPTION: returns threshold A (minimum sequence identity observed for match with same species)
# ARGUMENTS:
#   1. this
# RETURN:
#   <float> sequence identity (%)

sub getFractionA($);
# METHOD: reader
# DESCRIPTION: returns fraction of identical bases observed for match with same species
# ARGUMENTS:
#   1. this
# RETURN:
#   <string> fraction of identical bases

sub getThresholdB($);
# METHOD: reader
# DESCRIPTION: returns threshold B (maximum sequence identity observed for match with different species)
# ARGUMENTS:
#   1. this
# RETURN:
#   <float> sequence identity (%)

sub getFractionB($);
# METHOD: reader
# DESCRIPTION: returns fraction of identical bases observed for match with different species
# ARGUMENTS:
#   1. this
# RETURN:
#   <string> fraction of identical bases

sub getFeature($);
# METHOD: reader
# DESCRIPTION: returns feature (often species)
# ARGUMENTS:
#   1. this
# RETURN:
#   <string> feature string 

sub getComments($);
# METHOD: reader
# DESCRIPTION: returns threshold comments
# ARGUMENTS:
#   1. this
# RETURN:
#   <string> threshold type description

sub getUserDefinedField($$);
# METHOD: reader
# DESCRIPTION: returns value stored for a user-defined field identifier
#   used in conjunction with hasUserDefinedField()
# ARGUMENTS:
#   1. this
#   2. <string> field identifier
# RETURN:
#   <string> value stored for user-defined field identifier

#-------------------------
#_ INTERFACE: Set methods
#-------------------------
sub setIdentifier($$);
# METHOD: modifier
# DESCRIPTION: sets profile identifier
# ARGUMENTS:
#   1. this
#   2. <string> profile identifier
# RETURN:
#   void

sub setThresholdA($$);
# METHOD: modifier
# DESCRIPTION: sets minimum sequence identity observed for match with same species
# ARGUMENTS:
#   1. this
#   2. <float> sequence identity (%)
# RETURN:
#   void

sub setFractionA($$);
# METHOD: modifier
# DESCRIPTION: sets fraction of identical bases observed for match with same species
# ARGUMENTS:
#   1. this
#   2. <string> fraction of identical bases
# RETURN:
#   void

sub setThresholdB($$);
# METHOD: modifier
# DESCRIPTION: sets maximum sequence identity observed for match with different species
# ARGUMENTS:
#   1. this
#   2. <float> sequence identity (%)
# RETURN:
#   void

sub setFractionB($$);
# METHOD: modifier
# DESCRIPTION: sets fraction of identical bases observed for match with different species
# ARGUMENTS:
#   1. this
#   2. <string> fraction of identical bases
# RETURN:
#   void

sub setFeature($$);
# METHOD: modifier
# DESCRIPTION: sets feature (often species)
# ARGUMENTS:
#   1. this
#   2. <string> feature string
# RETURN:
#   void

sub setComments($$);
# METHOD: modifier
# DESCRIPTION: sets threshold comments
# ARGUMENTS:
#   1. this
#   2. <string> comments string
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

sub print($$);
# METHOD: output
# DESCRIPTION: writes contents of a single ScanThresholdsEntry object to an open filehandle
# ARGUMENTS:
#   1. this
#   2. <filehandle> output filehandle
# RETURN:
#   void


#------------------------------------------------------------------------------
# IMPLEMENTATION 
#---------------

#_ Constructor

sub new($;$)
{
        my ($class) = $ARG[0];
        my ($line) = $ARG[1] || undef;

        my $this = {
                'identifier' => q{},
                'threshold_a' => -1,
                'fraction_a' => '0/0',
                'threshold_b' => -1,
                'fraction_b' => '0/0',
                'feature' => q{},
                'comments' => 'N/A',
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
	# Return ScanThresholdsEntry object
	else { return $this; }

	# Returns object
	return $this;

}

# get methods
sub getIdentifier($)	{ return $ARG[0]->{'identifier'}; }
sub getThresholdA($)	{ return $ARG[0]->{'threshold_a'}; }
sub getFractionA($)	{ return $ARG[0]->{'fraction_a'}; }
sub getThresholdB($)	{ return $ARG[0]->{'threshold_b'}; }
sub getFractionB($)	{ return $ARG[0]->{'fraction_b'}; }
sub getFeature($)	{ return $ARG[0]->{'feature'}; }
sub getComments($)		{ return $ARG[0]->{'comments'}; }
sub getUserDefinedField($$)	{ return $ARG[0]->{'user_defined_field'}{$ARG[1]}; }


# set methods
sub setIdentifier($$)	{ $ARG[0]->{'identifier'} = $ARG[1]; return; }
sub setThresholdA($$)	{ $ARG[0]->{'threshold_a'} = $ARG[1]; return; }
sub setFractionA($$)	{ $ARG[0]->{'fraction_a'} = $ARG[1]; return; }
sub setThresholdB($$)	{ $ARG[0]->{'threshold_b'} = $ARG[1]; return; }
sub setFractionB($$)	{ $ARG[0]->{'fraction_b'} = $ARG[1]; return; }
sub setFeature($$)	{ $ARG[0]->{'feature'} = $ARG[1]; return; }
sub setComments($$)	{ $ARG[0]->{'comments'} = $ARG[1]; return; }

sub setUserDefinedField($$$)
{
        my ($this, $key, $value) = @ARG;
        $this->{'user_defined_field'}{$key} = $value;
	return;
}

# has methods
sub hasUserDefinedField($$)    { return exists $ARG[0]->{'user_defined_field'}{$ARG[1]} }

# other methods
sub print($$)
{
	my ( $this, $fhOut ) = @ARG;

	# Write results to file - FIVE COLUMNS
	# Report sequence identities to 5 decimal places 
	# Report fractions as strings - exactly as they were defined
	printf $fhOut "%s\t%.5f\t%s\t%.5f\t%s\t%s\t%s\n",
		$this->getIdentifier(),
		$this->getThresholdA(),
		$this->getFractionA(),
		$this->getThresholdB(),
		$this->getFractionB(),
		$this->getFeature(),
		$this->getComments();

	return;
}


#------------------------------------------------------------------------------
# IMPLEMENTATION 
#---------------

#_ Private class methods

sub _ReadLine($$);

#-----------------------------------------------------------
# Function: _ReadLine
#
# Reads tab separated line and populates the object
#
# Failure: line does not contain correct number of fields
# Failure: thresholds are not within allowed range (0-100)
#
# Returns: EXIT_SUCCESS(1) or EXIT_FAILURE(0)
#
#-----------------------------------------------------------
sub _ReadLine($$)
{
	my ( $this, $line ) = @ARG;

	my $logger = get_logger();

	chomp $line;
	$line =~ s/^\s+//;
	my @flds = split /\t/, $line;
	if(scalar(@flds) != 7 ) {
		$logger->error("Parse error for line: $line\n");
		# EXIT_FAILURE
		return 0;
	}

	# SEVEN columns
	$this->setIdentifier($flds[0]);
	$this->setThresholdA($flds[1]);
	$this->setFractionA($flds[2]);
	$this->setThresholdB($flds[3]);
	$this->setFractionB($flds[4]);
	$this->setFeature($flds[5]);
	$this->setComments($flds[6]);

	my $errors = 0;
	my $identifier = $this->getIdentifier();

	# Calculate Thresholds from fractions (if available) to avoid rounding problems
	# Overwrite the Threshold A and Threshold B values 
	# Not available = default string '0/0'
	#
	if($this->getFractionA() ne '0/0' ) {
		# Calculate sequence identity from fraction
		if($this->getFractionA() =~ m/^\d+\/\d+$/) {
			my ($fractionA_Top, $fractionA_Bottom) = split /\//, $this->getFractionA();
			# Protect against division by zero
			if($fractionA_Bottom != 0) { 
				my $thresholdA = 100 * $fractionA_Top / $fractionA_Bottom;
				$this->setThresholdA($thresholdA);
			}
			else {
				$logger->error("Denominator of Threshold A fraction must be a positive integer [$identifier]: ", $this->getFractionA());
				$errors++;
			}
		}
		else {
			$logger->error("Incorrect format for Threshold A fraction [$identifier]: ", $this->getFractionA());
			$logger->error("Required format = 'positive_integer/positive_integer'");
			$errors++;
		}
	}

	if($this->getFractionB() ne '0/0' ) {
		# Calculate sequence identity from fraction
		if($this->getFractionB() =~ m/^\d+\/\d+$/) {
			my ($fractionB_Top, $fractionB_Bottom) = split /\//, $this->getFractionB();
			# Protect against division by zero
			if($fractionB_Bottom != 0) { 
				my $thresholdB = 100 * $fractionB_Top / $fractionB_Bottom;
				$this->setThresholdB($thresholdB);
			}
			else {
				$logger->error("Denominator of Threshold B fraction must be a positive integer [$identifier]: ", $this->getFractionB());
				$errors++;
			}

		}
		else {
			$logger->error("Incorrect format for Threshold B fraction [$identifier]: ", $this->getFractionB());
			$logger->error("Required format = 'positive_integer/positive_integer'");
			$errors++;
		}
	}

	# Check thresholds are within allowed range (0-100)
	if($this->getThresholdA() > 100 || $this->getThresholdA() < 0) {
		$logger->error("Threshold A is outside allowed threshold range (0-100) [$identifier]: ", $this->getThresholdA());
		$errors++;
	}
	if($this->getThresholdB() > 100 || $this->getThresholdB() < 0) {
		$logger->error("Threshold B is outside allowed threshold range (0-100) [$identifier]: ", $this->getThresholdB());
		$errors++;
	}
	if($this->getThresholdA() < $this->getThresholdB()) {
		$logger->error("Threshold A is lower than Threshold B [$identifier]: ", $this->getThresholdA());
		$errors++;
	}

	# EXIT_FAILURE(0) if any errors detected
	if($errors > 0) {
		return 0;
	}

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
