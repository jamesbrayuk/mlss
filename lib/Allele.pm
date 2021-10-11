#==============================================================================
# MODULE: Allele.pm
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
# Allele class.
# 	- Used for encapsulating a single entry of an Allele entry
#
#==============================================================================

#==============================================================================
# CLASS: Allele
#==========================
# DESCRIPTION:
# Class for encapsulating a single entry of an Allele entry
#
# AFFILIATIONS:
# Often used with Profile.pm
#
# NOTE: does not have a setAlleleIdentifier() method
# Allele identifier always created on-the-fly from locus identifier and allele index variables
#
#---------------------------------------------------------------------------------

#_ Class declaration

package Allele;

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

sub getLocusIdentifier($);
# METHOD: reader
# DESCRIPTION: returns locus identifier
# ARGUMENTS:
#   1. this
# RETURN:
#   <string> locus identifier

sub getAlleleIndex($);
# METHOD: reader
# DESCRIPTION: returns allele index (string - can be 'N' or contain square brackets)
# ARGUMENTS:
#   1. this
# RETURN:
#   <string> allele index

sub getAlleleIdentifier($);
# METHOD: reader
# DESCRIPTION: returns allele identifier (locus id + '_' + allele index)
#   value is calculated on-the-fly from locus identifier and allele index variables
# ARGUMENTS:
#   1. this
# RETURN:
#   <string> allele identifier

sub getField($$);
# METHOD: reader
# DESCRIPTION: returns value stored for a user-defined field identifier
#   used in conjunction with hasField()
# ARGUMENTS:
#   1. this
#   2. <string> field identifier
# RETURN:
#   <string> value stored for user-defined field identifier

#-------------------------
#_ INTERFACE: Set methods
#-------------------------

sub setLocusIdentifier($$);
# METHOD: modifier
# DESCRIPTION: sets locus identifier
# ARGUMENTS:
#   1. this
#   2. <string> locus identifier string
# RETURN:
#   void

sub setAlleleIndex($$);
# METHOD: modifier
# DESCRIPTION: sets allele index
# ARGUMENTS:
#   1. this
#   2. <string> allele index string
# RETURN:
#   void

sub setField($$$);
# METHOD: modifier
# DESCRIPTION: sets user-defined field value associated with a field identifier
# ARGUMENTS:
#   1. this
#   2. <string> field identifier string
#   3. <string> field value
# RETURN:
#   void

#-------------------------
#_ INTERFACE: Other methods
#-------------------------

sub hasField($$);
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

sub new($)
{
        my ($class) = $ARG[0];
        my ($line) = $ARG[1] || 0;

        my $this = {
                'allele_index' => q{},
                'locus_identifier' => q{},
		'field' => {},
	};

        bless $this, $class;

	# Returns object or 'undef'
	return $this;

}


#------------------------------------------
#_ IMPLEMENTATION: Public instance methods
#------------------------------------------

#------------------------------
#_ IMPLEMENTATION: Get methods
#------------------------------
sub getLocusIdentifier($)	{ return $ARG[0]->{'locus_identifier'}; }
sub getAlleleIndex($)		{ return $ARG[0]->{'allele_index'}; }

sub getAlleleIdentifier($) {
	return $ARG[0]->{'locus_identifier'} . "_" . $ARG[0]->{'allele_index'};
}

sub getField($$)		{ return $ARG[0]->{'field'}{$ARG[1]}; }


#------------------------------
#_ IMPLEMENTATION: Set methods
#------------------------------
sub setLocusIdentifier($$)	{ $ARG[0]->{'locus_identifier'} = $ARG[1]; return 1; }
sub setAlleleIndex($$)		{ $ARG[0]->{'allele_index'} = $ARG[1]; return 1; }

sub setField($$$)
{
        my ($this, $key, $value) = @ARG;
        $this->{'field'}{$key} = $value;
	return;
}

#--------------------------------
#_ IMPLEMENTATION: Other methods
#--------------------------------
sub hasField($$)    { return exists $ARG[0]->{'field'}{$ARG[1]} }

#=============
# END OF CLASS
#==============================================================================

#==============
# END OF MODULE
#==============================================================================
1;
