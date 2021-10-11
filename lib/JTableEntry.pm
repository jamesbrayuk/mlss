#==============================================================================
# MODULE: JTableEntry.pm
#==================================
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
# This simple module contains JTable class
# and is used for reading a tab formatted table into a data structure
#
#==============================================================================

#==============================================================================
# CLASS: JTableEntry
#======================
# DESCRIPTION:
# Class for accessing userdefined data as an object
#
# AFFILIATIONS:
# None
#
#---------------------------------------------------------------------------------

#_ Class declaration

package JTableEntry;

#_ Include libraries

use strict;
use English;
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

#_ Constructor

sub new($)
{
        my ($class) = $ARG[0];

        my $this = {
		'field' => {},
	};
		
        bless $this, $class;

	# Return object
	return $this;

}

# get methods
sub getField($$)
{
        my ($this, $key) = @ARG;
        return $this->{'field'}{$key};
}


# set methods
sub setField($$$)
{
        my ($this, $key, $value) = @ARG;
        $this->{'field'}{$key} = $value;
	return;
}


# has methods
sub hasField($$)    { return exists $ARG[0]->{'field'}{$ARG[1]}; }

#=============
# END OF CLASS
#==============================================================================

#==============
# END OF MODULE
#==============================================================================
1;
