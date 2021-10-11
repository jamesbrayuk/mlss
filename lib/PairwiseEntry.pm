#==============================================================================
# MODULE: PairwiseEntry.pm
#=========================
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
# This module contains the PairwiseEntry class.
# Used for encapsulating a single line of a Scan Pair File (SPF)
#
#==============================================================================

#==============================================================================
# CLASS: PairwiseEntry
#=====================
# DESCRIPTION:
# Class for accessing data in each line of a Scan Pair File (SPF)
#
# CONVENTIONS:
# Seq refers to the whole sequence
# Segment refers to a partial sequence - found in alignment output
# Query = Query sequence
# Match = Match sequence
#
# REQUIRES:
# Log4perl
#
# SCAN PAIR FILE FORMAT 1.4 (19 columns)
# Column 1:  Query Sequence Name
# Column 2:  Query Sequence Feature
# Column 3:  Match Sequence Name
# Column 4:  Match Sequence Feature
# Column 5:  Query Sequence Length
# Column 6:  Match Sequence Length
# Column 7:  Start Position of Query Segment
# Column 8:  End Position of Query Segment
# Column 9:  Start Position of Match Segment
# Column 10: End Position of Match Segment
# Column 11: Sequence Identity
# Column 12: Total Length of Segment 
# Column 13: Evalue of the Match
# Column 14: Log Evalue (base 10) of the Match
# Column 15: Raw/Bit Score of the Match
# Column 16: Iteration
# Column 17: True Positive (TRUE_POS) or False Positive (FALSE_POS)
# Column 18: Strand Orientation
# Column 19: Number of Identical Matches
#
#---------------------------------------------------------------------------------

#_ Class declaration

package PairwiseEntry;

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
#   2. <string> [optional] Scan Pair File line
# RETURN:
#   1. this
#   OR Failure(implicit undef): if line passed AND failed to read line

#-------------------------------------
#_ INTERFACE: Public instance methods
#-------------------------------------

#-------------------------
#_ INTERFACE: Get methods
#-------------------------
sub getQuerySeqName($);
# METHOD: reader
# DESCRIPTION: returns query sequence name
# ARGUMENTS:
#   1. this
# RETURN:
#   <string> query sequence name

sub getQueryFeature($);
# METHOD: accessor
# DESCRIPTION: returns query sequence feature
# ARGUMENTS:
#   1. this
# RETURN:
#   1. <string> query sequence feature

sub getQuerySeqLength($);
# METHOD: reader
# DESCRIPTION: returns query sequence length
# ARGUMENTS:
#   1. this
# RETURN:
#   1. <string> query sequence length

sub getMatchSeqName($);
# METHOD: reader
# DESCRIPTION: returns match sequence name
# ARGUMENTS:
#   1. this
# RETURN:
#   1. <string> match sequence name

sub getMatchFeature($);
# METHOD: reader
# DESCRIPTION: returns match sequence feature
# ARGUMENTS:
#   1. this
# RETURN:
#   1. <string> match sequence feature

sub getMatchSeqLength($);
# METHOD: reader
# DESCRIPTION: returns match sequence length
# ARGUMENTS:
#   1. this
# RETURN:
#   1. <integer> match sequence length

sub getQuerySegmentStart($);
# METHOD: reader
# DESCRIPTION: returns query segment start position
# ARGUMENTS:
#   1. this
# RETURN:
#   1. <integer> query segment start position

sub getQuerySegmentEnd($);
# METHOD: reader
# DESCRIPTION: returns query segment end position
# ARGUMENTS:
#   1. this
# RETURN:
#   1. <integer> query segment end position

sub getMatchSegmentStart($);
# METHOD: reader
# DESCRIPTION: returns match segment start position
# ARGUMENTS:
#   1. this
# RETURN:
#   1. <integer> match segment start position

sub getMatchSegmentEnd($);
# METHOD: reader
# DESCRIPTION: returns match segment end position
# ARGUMENTS:
#   1. this
# RETURN:
#   1. <integer> match segment end position

sub getSeqId($);
# METHOD: reader
# DESCRIPTION: returns sequence identity of matching segment
# ARGUMENTS:
#   1. this
# RETURN:
#   1. <float> sequence identity

sub getTotalSegmentLength($);
# METHOD: reader
# DESCRIPTION: returns total segment length 
# ARGUMENTS:
#   1. this
# RETURN:
#   1. <integer> total segment length

sub getScore($);
# METHOD: reader
# DESCRIPTION: returns bit/raw score from the sequence search algorithm
# ARGUMENTS:
#   1. this
# RETURN:
#   1. <float> bit/raw score

sub getEvalue($);
# METHOD: reader
# DESCRIPTION: returns E-value for the match
# ARGUMENTS:
#   1. this
# RETURN:
#   1. <number> E-value

sub getLogEvalue($);
# METHOD: reader
# DESCRIPTION: returns logarithm (base 10) of E-value for the match
# ARGUMENTS:
#   1. this
# RETURN:
#   1. <number> log10 E-value

sub getIteration($);
# METHOD: reader
# DESCRIPTION: returns iteration for the match
# ARGUMENTS:
#   1. this
# RETURN:
#   1. <int> iteration

sub getTrueOrFalse($);
# METHOD: reader
# DESCRIPTION: returns TRUE_POS or FALSE_POS from scan pair file
# ARGUMENTS:
#   1. this
# RETURN:
#   1. <string> TRUE_POS or FALSE_POS

sub getStrandOrientation($);
# METHOD: reader
# DESCRIPTION: returns FORWARD or REVERSE from scan pair file
# ARGUMENTS:
#   1. this
# RETURN:
#   1. <string> FORWARD or REVERSE

sub getNumberOfIdenticalMatches($);
# METHOD: reader
# DESCRIPTION: returns number of identical matches
# ARGUMENTS:
#   1. this
# RETURN:
#   1. <integer> number of identical matches

sub getLine($);
# METHOD: reader
# DESCRIPTION: returns scan pair file line
# ARGUMENTS:
#   1. this
# RETURN:
#   1. <string> scan pair file line

sub getQuerySegmentLength($);
# METHOD: reader
# DESCRIPTION: returns query segment length (not in scan pair file)
#   (calculated from $this->getQuerySegmentEnd - $this->getQuerySegmentStart + 1)
# ARGUMENTS:
#   1. this
# RETURN:
#   1. <integer> query segment length

sub getMatchSegmentLength($);
# METHOD: reader
# DESCRIPTION: returns match segment length (not in scan pair file)
#   (calculated from $this->getMatchSegmentEnd - $this->getMatchSegmentStart + 1)
# ARGUMENTS:
#   1. this
# RETURN:
#   1. <integer> match segment length

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

sub setQuerySeqName($$);
# METHOD: reader
# DESCRIPTION: sets query sequence name
# ARGUMENTS:
#   1. this
#   2. <string> query sequence name
# RETURN:
#   void

sub setQueryFeature($$);
# METHOD: reader
# DESCRIPTION: query sequence feature
# ARGUMENTS:
#   1. this
#   2. <string> query sequence feature
# RETURN:
#   void

sub setQuerySeqLength($$);
# METHOD: reader
# DESCRIPTION: sets query sequence length
# ARGUMENTS:
#   1. this
#   2. <integer> query sequence length
# RETURN:
#   void

sub setMatchSeqName($$);
# METHOD: reader
# DESCRIPTION: sets match sequence name
# ARGUMENTS:
#   1. this
#   2. <string> match sequence name
# RETURN:
#   void

sub setMatchFeature($$);
# METHOD: reader
# DESCRIPTION: sets match sequence feature
# ARGUMENTS:
#   1. this
#   2. <string> match sequence feature
# RETURN:
#   void

sub setMatchSeqLength($$);
# METHOD: reader
# DESCRIPTION: sets match sequence length
# ARGUMENTS:
#   1. this
#   2. <integer> match sequence length
# RETURN:
#   void

sub setQuerySegmentStart($$);
# METHOD: reader
# DESCRIPTION: sets query segment start position
# ARGUMENTS:
#   1. this
#   2. <integer> query segment start position
# RETURN:
#   void

sub setQuerySegmentEnd($$);
# METHOD: reader
# DESCRIPTION: sets query segment end position
# ARGUMENTS:
#   1. this
#   2. <integer> query segment end position
# RETURN:
#   void

sub setMatchSegmentStart($$);
# METHOD: reader
# DESCRIPTION: sets match segment start position
# ARGUMENTS:
#   1. this
#   2. <integer> match segment start position
# RETURN:
#   void

sub setMatchSegmentEnd($$);
# METHOD: reader
# DESCRIPTION: sets match segment end position
# ARGUMENTS:
#   1. this
#   2. <integer> match segment end position
# RETURN:
#   void

sub setSeqId($$);
# METHOD: reader
# DESCRIPTION: sets sequence identity of matching segment
# ARGUMENTS:
#   1. this
#   2. <float> sequence identity
# RETURN:
#   void

sub setTotalSegmentLength($$);
# METHOD: reader
# DESCRIPTION: sets total segment length 
# ARGUMENTS:
#   1. this
#   2. <integer> total segment length 
# RETURN:
#   void

sub setScore($$);
# METHOD: reader
# DESCRIPTION: sets bit/raw score from the sequence search algorithm
# ARGUMENTS:
#   1. this
#   2. <float> bit/raw score
# RETURN:
#   void

sub setEvalue($$);
# METHOD: reader
# DESCRIPTION: sets E-value for the match
# ARGUMENTS:
#   1. this
#   2. <number> E-value
# RETURN:
#   void

sub setLogEvalue($$);
# METHOD: reader
# DESCRIPTION: sets logarithm (base 10) of E-value for the match
# ARGUMENTS:
#   1. this
#   2. <number> log10 E-value
# RETURN:
#   void

sub setIteration($$);
# METHOD: reader
# DESCRIPTION: sets iteration for the match
# ARGUMENTS:
#   1. this
#   2. <integer> iteration
# RETURN:
#   void

sub setTrueOrFalse($$);
# METHOD: reader
# DESCRIPTION: sets TRUE_POS or FALSE_POS from scan pair file
# ARGUMENTS:
#   1. this
#   2. <string> TRUE_POS or FALSE_POS
# RETURN:
#   void

sub setStrandOrientation($$);
# METHOD: reader
# DESCRIPTION: sets FORWARD OR REVERSE from scan pair file
# ARGUMENTS:
#   1. this
#   2. <string> FORWARD OR REVERSE
# RETURN:
#   void

sub setNumberOfIdenticalMatches($$);
# METHOD: reader
# DESCRIPTION: sets number of identical matches
# ARGUMENTS:
#   1. this
#   2. <integer> number of identical matches
# RETURN:
#   void

sub setLine($$);
# METHOD: reader
# DESCRIPTION: sets scan pair file line
# ARGUMENTS:
#   1. this
#   2. <string> scan pair file line
# RETURN:
#   void

sub setQuerySegmentLength($$);
# METHOD: reader
# DESCRIPTION: sets query segment length (not in scan pair file)
#   (calculated from $this->getQuerySegmentEnd - $this->getQuerySegmentStart + 1)
# ARGUMENTS:
#   1. this
#   2. <integer> query segment length
# RETURN:
#   void

sub setMatchSegmentLength($$);
# METHOD: reader
# DESCRIPTION: 
#   sets query segment length (not in scan pair file)
#   (calculated from $this->getQuerySegmentEnd - $this->getQuerySegmentStart + 1)
# ARGUMENTS:
#   1. this
#   2. <integer> query segment length
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


#--------------------------------
#_ IMPLEMENTATION: Other methods
#--------------------------------

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

#------------------------------
#_ IMPLEMENTATION: Constructor
#------------------------------

sub new ($;$)
{
        my ($class) = $ARG[0];
	my ($line) = $ARG[1] || undef;

        my $this = {
                'query_seq_name' 	=> '',
                'query_feature' 	=> '',
                'match_seq_name' 	=> '',
                'match_feature' 	=> '',
                'query_seq_length' 	=> 0,
                'match_seq_length' 	=> 0,
                'query_segment_start' 	=> 0,
                'query_segment_end' 	=> 0,
                'match_segment_start' 	=> 0,
                'match_segment_end' 	=> 0,
                'seq_id' 		=> 0,
                'total_segment_length' 	=> 0,
		'score'			=> 0,
		'evalue'		=> 0,
		'log_evalue'		=> 0,
                'true_or_false' 	=> '',
                'iteration' 		=> 0,
                'strand_orientation' 	=> '',
                'number_of_identical_matches' 	=> 0,
                'query_segment_length' 	=> 0,
                'match_segment_length' 	=> 0,
                'line' 			=> '',
		'user_defined_field' => {},
                };
        bless $this, $class;
	
	# Read the line
	if(defined $line) {
		# Problem reading line returns EXIT_FAILURE(0)
		# As caller wants an object, return implicit undef
		if(! $this->_ReadLine($line) ) { return; }
		else { return $this; } 
	}
	# Return PairwiseEntry object
	else { return $this; }

}

#------------------------------------------
#_ IMPLEMENTATION: Public instance methods
#------------------------------------------

#------------------------------
#_ IMPLEMENTATION: Get methods
#------------------------------

sub getMatchSeqName($)		{ return $ARG[0]->{'match_seq_name'}; }
sub getMatchFeature($)		{ return $ARG[0]->{'match_feature'}; }
sub getQuerySeqName($)		{ return $ARG[0]->{'query_seq_name'}; }
sub getQueryFeature($)		{ return $ARG[0]->{'query_feature'}; }
sub getMatchSeqLength($)	{ return $ARG[0]->{'match_seq_length'}; }
sub getQuerySeqLength($)	{ return $ARG[0]->{'query_seq_length'}; }
sub getQuerySegmentStart($)	{ return $ARG[0]->{'query_segment_start'}; }
sub getQuerySegmentEnd($)	{ return $ARG[0]->{'query_segment_end'}; }
sub getMatchSegmentStart($)	{ return $ARG[0]->{'match_segment_start'}; }
sub getMatchSegmentEnd($)	{ return $ARG[0]->{'match_segment_end'}; }
sub getSeqId($)			{ return $ARG[0]->{'seq_id'}; }
sub getTotalSegmentLength($)	{ return $ARG[0]->{'total_segment_length'}; }
sub getLogEvalue($)		{ return $ARG[0]->{'log_evalue'}; }
sub getEvalue($)		{ return $ARG[0]->{'evalue'}; }
sub getScore($)			{ return $ARG[0]->{'score'}; }
sub getIteration($)		{ return $ARG[0]->{'iteration'}; }
sub getTrueOrFalse($)		{ return $ARG[0]->{'true_or_false'}; }
sub getStrandOrientation($)	{ return $ARG[0]->{'strand_orientation'}; }
sub getNumberOfIdenticalMatches($)	{ return $ARG[0]->{'number_of_identical_matches'}; }
sub getLine($)			{ return $ARG[0]->{'line'}; }

# others
sub getQuerySegmentLength($)	{ return $ARG[0]->{'query_segment_length'}; }
sub getMatchSegmentLength($)	{ return $ARG[0]->{'match_segment_length'}; }

sub getUserDefinedField($$)	{ return $ARG[0]->{'user_defined_field'}{$ARG[1]}; }

#------------------------------
#_ IMPLEMENTATION: Set methods
#------------------------------
sub setMatchSeqName($$)		{ $ARG[0]->{'match_seq_name'} = $ARG[1]; return; }
sub setMatchFeature($$)		{ $ARG[0]->{'match_feature'} = $ARG[1]; return; }
sub setQuerySeqName($$)		{ $ARG[0]->{'query_seq_name'} = $ARG[1]	; return; }
sub setQueryFeature($$)		{ $ARG[0]->{'query_feature'} = $ARG[1]; return; }
sub setMatchSeqLength($$)	{ $ARG[0]->{'match_seq_length'} = $ARG[1]; return; }
sub setQuerySeqLength($$)	{ $ARG[0]->{'query_seq_length'} = $ARG[1]; return; }
sub setQuerySegmentStart($$)    { $ARG[0]->{'query_segment_start'} = $ARG[1]; return; }
sub setQuerySegmentEnd($$)    	{ $ARG[0]->{'query_segment_end'} = $ARG[1]; return; }
sub setMatchSegmentStart($$)	{ $ARG[0]->{'match_segment_start'} = $ARG[1]; return; }
sub setMatchSegmentEnd($$)	{ $ARG[0]->{'match_segment_end'} = $ARG[1]; return; }
sub setSeqId($$)		{ $ARG[0]->{'seq_id'} = $ARG[1]; return;  }
sub setTotalSegmentLength($$)	{ $ARG[0]->{'total_segment_length'} = $ARG[1]; return; }
sub setEvalue($$)		{ $ARG[0]->{'evalue'} = $ARG[1] ; return; }
sub setLogEvalue($$)		{ $ARG[0]->{'log_evalue'} = $ARG[1]; return; }
sub setScore($$)		{ $ARG[0]->{'score'} = $ARG[1]; return; }
sub setIteration($$)		{ $ARG[0]->{'iteration'} = $ARG[1]; return; }
sub setTrueOrFalse($$)		{ $ARG[0]->{'true_or_false'} = $ARG[1]; return; }
sub setStrandOrientation($$)	{ $ARG[0]->{'strand_orientation'} = $ARG[1]; return; }
sub setNumberOfIdenticalMatches($$)	{ $ARG[0]->{'number_of_identical_matches'} = $ARG[1]; return; }
sub setLine($$)			{ $ARG[0]->{'line'} = $ARG[1]; return; }

# others
sub setQuerySegmentLength($$)   { $ARG[0]->{'query_segment_length'} = $ARG[1]; return; }
sub setMatchSegmentLength($$)	{ $ARG[0]->{'match_segment_length'} = $ARG[1]; return; }

sub setUserDefinedField($$$)
{
        my ($this, $key, $value) = @ARG;
        $this->{'user_defined_field'}{$key} = $value;
	return;
}

#--------------------------------
#_ IMPLEMENTATION: Other methods
#--------------------------------

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

	#_ Logging system
	my $logger = get_logger();

	my ( $i, @cols );

	@cols = split /\s+/, $line;
        for ( $i=0; $i<$#cols; $i++ ) {
                $cols[$i] =~ s/^\s*//;
                $cols[$i] =~ s/\s*$//;
	}

	# If line does not contain 19 columns return EXIT_FAILURE(0)
	# uses SCAN PAIR FILE (SPF) FORMAT 1.4
	if(scalar(@cols) != 19) {
		$logger->error("Incorrect Line Format: ", $line);
		# Return EXIT_FAILURE(0)
		return 0;
        }
	
	$this->setQuerySeqName($cols[0]);
	$this->setQueryFeature($cols[1]);
	$this->setMatchSeqName($cols[2]);
	$this->setMatchFeature($cols[3]);
	$this->setQuerySeqLength($cols[4]);
	$this->setMatchSeqLength($cols[5]);
	$this->setQuerySegmentStart($cols[6]);
	$this->setQuerySegmentEnd($cols[7]);
	$this->setMatchSegmentStart($cols[8]);
	$this->setMatchSegmentEnd($cols[9]);
	$this->setSeqId($cols[10]);
	$this->setTotalSegmentLength($cols[11]);
	$this->setEvalue($cols[12]);
	$this->setLogEvalue($cols[13]);
	$this->setScore($cols[14]);
	$this->setIteration($cols[15]);
	$this->setTrueOrFalse($cols[16]);
	$this->setStrandOrientation($cols[17]);
	$this->setNumberOfIdenticalMatches($cols[18]);
	$this->setLine($line);

	# others
	$this->setQuerySegmentLength( $cols[7] - $cols[6] + 1 );
	$this->setMatchSegmentLength( $cols[9] - $cols[8] + 1 );

	# Return EXIT_SUCCESS
	return 1;
}

#=============
# END OF CLASS
#==============================================================================
1;
