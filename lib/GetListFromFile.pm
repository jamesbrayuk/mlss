#==============================================================================
# MODULE: GetListFromFile.pm
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
# Reads a file containing a single column of data into an array
# Reports any duplicate entries or empty lines
# Only first column is extracted even if there are multiple columns
#
# ARGUMENTS:
# 1. Filename string
# 2. reference to array to populate
# 3. (optional) [type:Integer] - first line to read
# 4. (optional) [type:Integer] - last line to read
#
# RETURNS: 
# 1 (EXIT_SUCCESS) or 0 (EXIT_FAILURE)
#
#==============================================================================

#_ Include libraries

use strict;
use warnings;
use English '-no_match_vars';
use FileHandle;
use Carp;
use Log::Log4perl qw(get_logger);
use version; our $VERSION = version->declare('v1.0.0');

#_ Custom Libraries

use NumericalChecks qw( IsInteger IsPositiveInteger );

#------------------------------------------------------------------------------
# IMPLEMENTATION 
#---------------

#------------------------------------------
#_ Public instance methods
#------------------------------------------

sub GetListFromFile($$;$$);

#---------------------------------------------------------------
# Function: GetListFromFile
# Populates <\@ Entries> with Array of Strings
#
# Input:
# 1. fIn [type:File]- input file
# 2. $aEntries [type:Reference] - reference to array to be populated
# 3. (optional) $firstLine [type:Integer] - first line to read
# 4. (optional) $lastLine [type:Integer] - last line to read
#
# EXIT_FAILURE:
# Performs checks on the $firstLine and $lastLine variables
# - both must be positive integers
# - $lastLine must be greater than or equal to $firstLine
#
# If omitted or passed as zero, $firstLine is set to 1 and $lastLine is set to the 
# last line of the input file (after removing empty lines)
#
# Returns: EXIT_SUCCESS(1) or EXIT_FAILURE(0)
#---------------------------------------------------------------
sub GetListFromFile($$;$$)
{
	my $fIn = $ARG[0];
	my $aEntries = $ARG[1];
	my $firstLine = $ARG[2] || 0;
	my $lastLine = $ARG[3] || 0;

	# Logging System
	my $logger = get_logger();

	# First Check - Fatal Errors
	# Line variables must be integers
	if(! IsInteger($firstLine) ) { $logger->error("[GENERAL] Variable is not an integer: $firstLine"); return 0; }
	if(! IsInteger($lastLine) ) { $logger->error("[GENERAL] Variable is not an integer: $lastLine"); return 0; }

	# default values are zero - which means read all entries in the file
	# Set first_line to 1 and last line to the count of non-empty lines in the file
	if($firstLine == 0) { $firstLine = 1; }
	if($lastLine == 0) { $lastLine = _GetNonEmptyLineCount( $fIn ); }
	if($lastLine == 0) { $logger->error("[GENERAL] Failed to determine line count for input file: $fIn"); return 0; }

	# Second Check - Fatal Errors
	# By this stage both numbers must be positive integers
	$logger->debug("FIRST LINE NUMBER: $firstLine");
	$logger->debug("LAST LINE NUMBER: $lastLine");
	if(! IsPositiveInteger($firstLine) ) { $logger->error("[GENERAL] Variable is not a positive integer: $firstLine"); return 0; }
	if(! IsPositiveInteger($lastLine) ) { $logger->error("[GENERAL] Variable is not a positive integer: $lastLine"); return 0; }

	# Third Check - Fatal Error
	# Last line must be greater than or equal to first line
	if($firstLine > $lastLine) { $logger->error("[GENERAL] First line is higher than last line"); return 0; }

	my $hEntries = {};
	my $counter = 0;

	# Open input filehandle
	my $fhIn = FileHandle->new( $fIn, "r" ) || croak "Cannot open input filehandle: $fIn";

	# loop through all entries, only counting non-empty lines
	LINE: while(my $line = $fhIn->getline)
	{
		chomp $line;
		if($line eq "") {
			$logger->error("[GENERAL] Empty line in input list file (skipping): ", $fIn);
			next LINE;
		}

		# Count all non-empty lines
		$counter++;

		# grab first column
		my @flds = split /\s+/, $line;
		my $name = $flds[0];

		# Only read lines between $firstLine and $lastLine variables
		if($counter < $firstLine || $counter > $lastLine) {
			$logger->debug("[COUNTER=$counter] Skipping entry outside line count range ($firstLine / $lastLine): $line");
			next LINE;
		}

		$logger->debug("[COUNTER=$counter] ENTRY: $name");
		
		# Catch duplicates
		if(! exists $hEntries->{$name} ) {
			push  @$aEntries, $name;
			$hEntries->{$name} = 1;
		}
		else {
			$logger->error("[COUNTER=$counter] Duplicate Entry in input file (skipping, but still counted): $name\n");
			next LINE;
		}
	}

	$fhIn->close;

	# Report Empty Array as an Error
	if(scalar(@$aEntries) == 0) {
		$logger->error("[GENERAL] NO ENTRIES READ FROM INPUT FILE: $fIn");
	}

	$logger->debug("[GENERAL] SAVED INPUT LINES: ", scalar(@$aEntries) );

	# EXIT_SUCCESS(1)
	return 1;
}


#------------------------------------------------------------------------------
# PRIVATE METHODS
#---------------

# PRIVATE METHODS
sub _GetNonEmptyLineCount($);

#---------------------------------------------------------------
# Function: _GetNonEmptyLineCount
#
# Input: $fIn <String>
# Returns: count of non-empty lines
#
# Reports presence of non-empty lines as logger errors
# Croaks if cannot open file for reading
#---------------------------------------------------------------
sub _GetNonEmptyLineCount($)
{
	my ( $fIn ) = @ARG;

	# Logging System
	my $logger = get_logger();

	# Open input filehandle
	my $fhIn = FileHandle->new( $fIn, "r" ) || croak "Cannot open input filehandle: $fIn";

	# Initialise line counter
	my $counter=0;

	# loop through all entries
	LINE: while(my $line = $fhIn->getline)
	{
		chomp $line;
		if($line eq "") {
			$logger->error("[GENERAL] Empty line in input list file (skipping): ", $fIn);
			next LINE;
		}

		# Count all non-empty lines
		$counter++;
	}

	# Close filehandle
	$fhIn->close;

	# save number of lines in the file
	$logger->debug("[GENERAL] TOTAL LINES COUNTED: ", $counter);

	# return number of lines
	return $counter;
}

#==============
# END OF MODULE
#==============================================================================
1;
