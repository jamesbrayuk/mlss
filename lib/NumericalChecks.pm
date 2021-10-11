#==============================================================================
# MODULE: NumericalChecks.pm
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
# Contains functions for performing typical numerical checks:
# IsInteger() and IsPositiveInteger()
#
# Discussion of different approaches can be found here:
# http://www.perlmonks.org/?node_id=614452
# 
# NOTE: Returns implicit undef (not explicit)
#==============================================================================

#_ Include libraries

use strict;
use warnings;
use English '-no_match_vars';
use FileHandle;
use Carp;
use Log::Log4perl qw(get_logger);
use version; our $VERSION = version->declare('v1.0.0');

#------------------------------------------------------------------------------
# IMPLEMENTATION 
#---------------

#------------------------------------------
#_ Public instance methods
#------------------------------------------

#---------------------------------------------------------------
# IsInteger
#---------------------------------------------------------------
sub IsInteger($)
{
	my $thing = shift;

	if($thing =~ /^\s*[\+\-]?\d+\s*$/ ) {
		return 1;
	}
	else {
		return;
	}
}

#---------------------------------------------------------------
# IsPositiveInteger
#---------------------------------------------------------------
sub IsPositiveInteger($)
{
	my $thing = shift;

	if( ( $thing =~ /^\s*[\+\-]?\d+\s*$/) and ($thing > 0) ) {
		return 1;
	}
	else {
		return;
	}
}

#==============
# END OF MODULE
#==============================================================================
1;
