#==============================================================================
# MODULE: ScanWriter.pm
#==========================
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
# This module contains the ScanWriter class.
#
#------------------------------------------------------------------------------
# SCAN FILE FORMAT 2.2 (13 columns)
# Tab separated format:
# Column 1: Rank Number
# Column 2: Contigs Filename
# Column 3: Profile Name (string)
# Column 4: Sequence Identity (%)
# Column 5: Profile Feature
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
# CLASS: ScanWriter
#==================
# DESCRIPTION:
# Class for handling Scan File Format (SFF) output
#
# REQUIRES:
# ScanEntry and Log4perl
#
# AFFILIATIONS:
# None
#
# EXAMPLE USAGE:
# my $oScanWriter = new ScanWriter( $fhOut, ScanWriter::SFF );
#
# OUTPUT FORMATS:
# ScanWriter::SFF - Scan File Format (SFF)
#
#--------------------------------------------------------------------

#_ Class declaration

package ScanWriter;

#_ Include libraries

use strict;
use English;
use Carp;
use ScanEntry;
use Log::Log4perl qw(get_logger);
use version; our $VERSION = version->declare('v1.0.0');

#------------------------------------------------------------------------------
# INTERFACE
#----------

#-------------------------
#_ Public class constants
#-------------------------

use constant SFF => 'ScanWriter::SFF';

#-------------------------
#_ INTERFACE: Constructor
#-------------------------

sub new($$$);
# Constructor
# WARNING
#   Failure(confess): if format is not one of the class constants
# ARGUMENTS:
#   1. class
#   2. <filehandle> output filehandle
#   3. <CONSTANT> format
# RETURN:
#   1. this

#-------------------------------------
#_ INTERFACE: Public instance methods
#-------------------------------------

#-------------------------
#_ INTERFACE: Get methods
#-------------------------
sub getReportingLimit($);
# METHOD: reader
# DESCRIPTION: returns reporting limit (number of lines to output)
# ARGUMENTS:
#   1. this
# RETURN:
#   <integer> reporting limit

#-------------------------
#_ INTERFACE: Set methods
#-------------------------
sub setReportingLimit($$);
# METHOD: modifier
# DESCRIPTION: sets reporting limit (number of lines to output)
# ARGUMENTS:
#   1. this
#   2. <integer> reporting limit
# RETURN:
#   void

sub print($$);
# METHOD: output
# DESCRIPTION: prints an array of ScanEntry objects to the filehandle
#   Failure (croak): If format is not supported
# ARGUMENTS:
#   1. this
#   2. <\@ ScanEntry> array of ScanEntry objects or single ScanEntry object
# RETURN:
#   void

sub printHeader($);
# METHOD: output
# DESCRIPTION: prints header string to the filehandle
#   Failure (croak): If format is not supported
# ARGUMENTS:
#   1. this
# RETURN:
#   void

#------------------------------------------------------------------------------
# IMPLEMENTATION 
#---------------

#------------------------------
#_ IMPLEMENTATION: Constructor
#------------------------------

sub new($$$)
{
	my($class, $ost, $format) = @ARG;

	#_ Logging system
	my $logger = get_logger();

	if( ( $format eq SFF ) == 0)
	{
		$logger->error("Unsupported output format: ", $format);
		confess "Unsupported output format: $format";
	}
    
	my $this = {
		'format' => $format,
		'ost'	 => $ost,
		'reporting_limit' => 0,
	};
	return bless $this, $class;
}

#------------------------------------------
#_ IMPLEMENTATION: Public instance methods
#------------------------------------------

#------------------------------
#_ IMPLEMENTATION: Get methods
#------------------------------
sub getReportingLimit($) { return $ARG[0]->{'reporting_limit'}; }

#------------------------------
#_ IMPLEMENTATION: Set methods
#------------------------------
sub setReportingLimit($$) { $ARG[0]->{'reporting_limit'} = $ARG[1]; return; }

#--------------------------------
#_ IMPLEMENTATION: Other methods
#--------------------------------
sub print($$)
{
	my ( $this, $arrayOrScalar ) = @ARG;

	#_ Logging system
	my $logger = get_logger();

	my ( $aScanEntries ) = [];

	# Check for array or single object
	if( ref($arrayOrScalar) eq "ARRAY") { $aScanEntries = $arrayOrScalar; }
	else { $aScanEntries->[0] = $arrayOrScalar; }

	my $format = $this->{'format'};
	
	# Check for format
	if ( SFF eq $format ) { $this->_WriteScanLine( $this->{'ost'}, $aScanEntries ) }
	else {
		$logger->error("Unsupported output format: ", $format);
		croak( "Unsupported output format: $format");
	}
}

sub printHeader($)
{
	my ( $this ) = @ARG;

	#_ Logging system
	my $logger = get_logger();

	my $format = $this->{'format'};

	if ( SFF eq $format ) { $this->_WriteHeaderLine( $this->{'ost'} ) }
	else {
		$logger->error("Unsupported output format: ", $format);
		croak( "Unsupported output format: $format" );
	}
}

#------------------------------------------------------------------------------
# IMPLEMENTATION 
#---------------

#_ Private class methods

sub _WriteScanLine($$$);
sub _WriteHeaderLine($);

#-----------------------------------------------------------
# Function: _WriteScanLine
#-----------------------------------------------------------
sub _WriteScanLine($$$)
{
	my ( $this, $fhOut, $aScanEntries ) = @ARG;

	my $limit = $this->getReportingLimit();

	# if limit is zero then set limit to all lines
	if($limit == 0) {
		$limit = scalar(@$aScanEntries);
	}

	my $count = 0;

	# loop through all ScanEntries
	ENTRY: foreach my $oScanEntry ( @$aScanEntries )
	{
		# increment counter
		$count++;

		# bail out if count exceeds the reporting limit
		if($count > $limit) { last ENTRY; }

		# Calculate nucleotide overlap on the fly
		# Overlap is always divided by Profile Nucleotide Count
		# Protect against division by zero
		my $nucleotideOverlap = 0;
		if($oScanEntry->getProfileNucleotideCount() != 0) {
	 		$nucleotideOverlap = 100 * $oScanEntry->getMatchedNucleotideCount() / 
			$oScanEntry->getProfileNucleotideCount();
		}

		# Calculate sequence identity on the fly
		# Denominator was set when data was calculated or read from file 
		# Protect against division by zero
		my $sequenceIdentity = 0;
		if($oScanEntry->getSequenceIdentityDenominator() != 0) {
			$sequenceIdentity = 100 * $oScanEntry->getIdenticalNucleotideCount() /
			$oScanEntry->getSequenceIdentityDenominator();
		}

		printf $fhOut "%d\t%s\t%s\t%.5f\t%s\t%s\t%.5f\t%d/%d\t%d/%d\t%d/%d\t%d\t%s\t%s\n",
			$oScanEntry->getRankNumber(),              # column 1
			$oScanEntry->getContigsFilename(),         # column 2
			$oScanEntry->getProfileName(),             # column 3
			$sequenceIdentity,                         # column 4
			$oScanEntry->getProfileFeature(),          # column 5
			$oScanEntry->getTrafficLightColour(),      # column 6
			$nucleotideOverlap,                        # column 7

			# Allele counts
			$oScanEntry->getMatchedAlleleCount(),      # column 8A
			$oScanEntry->getProfileAlleleCount(),      # column 8B

			# Sequence identity
			$oScanEntry->getIdenticalNucleotideCount(),    # column 9A
			$oScanEntry->getSequenceIdentityDenominator(),  # column 9B

			# Overlap
			$oScanEntry->getMatchedNucleotideCount(),      # column 10A
			$oScanEntry->getProfileNucleotideCount(),      # column 10B

			# Miscellaneous
			$oScanEntry->getTotalBlastScore(),             # column 11
			$oScanEntry->getProfileNumericIdentifier(),      # column 12
			$oScanEntry->getIdentityCalculationMethod();      # column 13
	}
}


sub _WriteHeaderLine($)
{
	my ( $fhOut ) = @ARG;

	printf $fhOut "#Rank\tFilename\tProfile Name\tSequence Identity\tProfile Feature\t";
	printf $fhOut "Traffic Light Colour\t";
	printf $fhOut "Nucleotide Overlap\t";
	printf $fhOut "Matched Allele Count / Profile Allele Count\t";
	printf $fhOut "Matched Nucleotide Identities / Profile Nucleotide Count\t";
	printf $fhOut "Matched Nucleotide Count / Profile Nucleotide Count\tTotal Blast Score\t";
	printf $fhOut "Profile Numeric Identifier\tIdentity Calculation Method\n";

}


#=============
# END OF CLASS
#==============================================================================
1;
