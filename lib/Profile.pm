#==============================================================================
# MODULE: Profile.pm
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
# Profile class.
# 	- Used for encapsulating a single entry of a PROFILE entry
#
#==============================================================================

#==============================================================================
# CLASS: Profile
#==========================
# DESCRIPTION:
# Class for encapsulating a single entry of PROFILE entry
#
# AFFILIATIONS:
# Allele
#
# CONVENTIONS:
# Profile Identifier - numeric value (isolate id or rST)
# Profile Name - e.g. a concatenated string 'ISOLATE_1' or 'RST_1' - prefix describes profile source
# Profile Alias - field used for storing another name/identifier as required
#
# Profile names of entries generated from Isolate database file using 'id' 
#   field are prefixed: 'ISOLATE_' (e.g. ISOLATE_1)
# Profile names of entries generated from Sequence Definition file using 'rST' 
#   field are prefixed: 'RST_' (e.g. RST_1)
#
#---------------------------------------------------------------------------------

#_ Class declaration

package Profile;

#_ Include libraries

use strict;
use warnings;
use English '-no_match_vars';
use Log::Log4perl qw(get_logger);
use Allele;
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
#   1. class
# RETURN:
#   this

#-------------------------------------
#_ INTERFACE: Public instance methods
#-------------------------------------

#-------------------------
#_ INTERFACE: Get methods
#-------------------------
sub getIdentifier($);
# METHOD: reader
# DESCRIPTION: returns profile identifier (numeric)
# ARGUMENTS:
#   1. this
# RETURN:
#   <integer> profile identifier NUMBER 

sub getFeature($);
# METHOD: reader
# DESCRIPTION: returns profile feature string (e.g. species)
# ARGUMENTS:
#   1. this
# RETURN:
#   <string> profile feature 

sub getName($);
# METHOD: reader
# DESCRIPTION: returns profile name (e.g. 'ISOLATE_1' or 'RST_1')
# ARGUMENTS:
#   1. this
# RETURN:
#   <string> profile name

sub getAlias($);
# METHOD: reader
# DESCRIPTION: returns profile alias (e.g. Isolate Identifier)
# ARGUMENTS:
#   1. this
# RETURN:
#   <string> profile alias

sub getAlleles($);
# METHOD: reader
# DESCRIPTION: returns Allele objects
# ARGUMENTS:
#   1. this
# RETURN:
#   <\@ Allele> reference to array of Allele objects

sub getAlleleCount($);
# METHOD: reader
# DESCRIPTION: returns number of Allele objects in array
# ARGUMENTS:
#   1. this
# RETURN:
#   <integer> Allele object count

sub getField($$);
# METHOD: reader
# DESCRIPTION: returns value stored for a user-defined field identifier
#   used in conjunction with hasUserDefinedField()
# ARGUMENTS:
#   1. this
#   2. <string> field identifier
# RETURN:
#   <string> value stored for user-defined field identifier

sub getHashByAlleleIdentifier($);
# METHOD: reader
# DESCRIPTION: returns hash of Allele objects 
# ARGUMENTS:
#   1. this
# RETURN:
#   <\%> reference to hash. Key: allele identifier, Value: Allele object

sub getHashByLocusIdentifierAndAlleleIndex($);
# METHOD: reader
# DESCRIPTION: returns hash of Allele objects 
# ARGUMENTS:
#   1. this
# RETURN:
#   <\%> reference to hash. 
#   Key 1: locus identifier, Key 2: allele index, Value: Allele object

#-------------------------
#_ INTERFACE: Set methods
#-------------------------
sub setIdentifier($$);
# METHOD: modifier
# DESCRIPTION: sets profile identifier (numeric)
# ARGUMENTS:
#   1. this
#   2. <string> profile NUMBER
# RETURN:
#   void

sub setFeature($$);
# METHOD: modifier
# DESCRIPTION: sets profile feature string (e.g. species)
# ARGUMENTS:
#   1. this
#   2. <string> profile feature
# RETURN:
#   void

sub setName($$);
# METHOD: modifier
# DESCRIPTION: sets profile name (e.g. 'ISOLATE_1' or 'RST_1')
# ARGUMENTS:
#   1. this
#   2. <string> profile name
# RETURN:
#   void

sub setAlias($$);
# METHOD: modifier
# DESCRIPTION: sets profile alias (e.g. Isolate Name)
# ARGUMENTS:
#   1. this
#   2. <string> profile alias
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

sub addAllele($$);
# METHOD: modifier
# DESCRIPTION: adds an Allele object to internal array of Allele objects (push)
# ARGUMENTS:
#   1. this
#   2. <Allele> Allele object
# RETURN:
#   void


# Private instance methods
# None

#------------------------------------------------------------------------------
# IMPLEMENTATION 
#---------------

#_ Constructor

sub new($)
{
        my ($class) = $ARG[0];

        my $this = {
                'identifier' => q{},
                'feature' => q{},
                'name' => q{},
                'alias' => q{},
                'alleles' => [],
		'field' => {},
	};

        bless $this, $class;

	# Returns object
	return $this;

}

#_ Get methods
sub getIdentifier($)	{ return $ARG[0]->{'identifier'}; }
sub getFeature($)	{ return $ARG[0]->{'feature'}; }
sub getName($)		{ return $ARG[0]->{'name'}; }
sub getAlias($)		{ return $ARG[0]->{'alias'}; }
sub getAlleles($)	{ return $ARG[0]->{'alleles'}; }
sub getAlleleCount($)	{ return scalar( @{ $ARG[0]->{'alleles'} } ); }
sub getField($$)	{ return $ARG[0]->{'field'}{$ARG[1]}; }

sub getHashByAlleleIdentifier($)
{
	my ($this) = @ARG;
	my $aAlleles = $this->getAlleles();
	my $hAlleles = {};
	foreach my $oAllele ( @$aAlleles ) {
		my $alleleIdentifier = $oAllele->getAlleleIdentifier();
		if(! exists $hAlleles->{ $alleleIdentifier }) {
			$hAlleles->{ $alleleIdentifier } = $oAllele;
		}
	}
	return $hAlleles;
}

sub getHashByLocusIdentifierAndAlleleIndex($)
{
	my ($this) = @ARG;
	my $aAlleles = $this->getAlleles();
	my $hAlleles = {};
	foreach my $oAllele ( @$aAlleles ) {
		my $locusIdentifier = $oAllele->getLocusIdentifier();
		my $alleleIndex = $oAllele->getAlleleIndex();
		if(! exists $hAlleles->{ $locusIdentifier }{$alleleIndex}) {
			$hAlleles->{ $locusIdentifier }{$alleleIndex} = $oAllele;
		}
	}
	return $hAlleles;
}

#_ Set methods
sub setIdentifier($$)	{ $ARG[0]->{'identifier'} = $ARG[1]; return; }
sub setFeature($$)	{ $ARG[0]->{'feature'} = $ARG[1]; return; }
sub setName($$)		{ $ARG[0]->{'name'} = $ARG[1]; return; }
sub setAlias($$)	{ $ARG[0]->{'alias'} = $ARG[1]; return; }
sub setAlleles($$)	{ $ARG[0]->{'alleles'} = $ARG[1]; return; }

sub setField($$$)
{
        my ($this, $key, $value) = @ARG;
        $this->{'field'}{$key} = $value;
	return;
}

#_ Has methods
sub hasField($$)    { return exists $ARG[0]->{'field'}{$ARG[1]}; }

#_ Other methods
sub addAllele($$)
{
	my ($this, $oAllele) = @ARG;
	push @{ $this->{'alleles'} }, $oAllele;
	return;
}


#=============
# END OF CLASS
#==============================================================================

#==============
# END OF MODULE
#==============================================================================
1;
