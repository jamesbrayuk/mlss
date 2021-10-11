#==============================================================================
# MODULE: DefaultLoggerConfig.pm
#===============================
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
# 
# Module contains one function which returns the standard Log4perl 
# configuration settings.
#
# Standard Log4perl levels allowed: DEBUG, INFO, WARN, ERROR, FATAL
# Custom level allowed: VERBOSE
#
# The 'info.log' file reports all logger statements of status INFO or higher
# The 'error.log' file reports all logger statements of status ERROR or higher
# All messages at the specified level or higher are output to the screen
#
# In addition:
# DEBUG - writes all debug statements to a file called 'debug.log'
# VERBOSE - same as DEBUG but does not create a 'debug.log' file
#
#==============================================================================

#_ Include libraries

use strict;
use warnings;
use English '-no_match_vars';
use Carp;
use version; our $VERSION = version->declare('v1.0.0');

#------------------------------------------------------------------------------
# IMPLEMENTATION 
#---------------

#------------------------------------------
#_ IMPLEMENTATION: Public instance methods
#------------------------------------------

#-----------------------------------------------------------------------------------
# Default Logging System Definitions
#-----------------------------------------------------------------------------------
sub DefaultLoggerConfig($)
{
	my ($level) = @ARG;
	
	my ($sConfig) = q{};

	# toggle 
	if($level eq "DEBUG") { $sConfig .= "	log4perl.logger = DEBUG, DebugFile, InfoFile, ErrorFile, Screen"; }
	elsif($level eq "VERBOSE") { $sConfig .= "	log4perl.logger = DEBUG, InfoFile, ErrorFile, Screen"; }
	elsif($level eq "INFO") { $sConfig .= "	log4perl.logger = INFO, InfoFile, ErrorFile, Screen"; }
	elsif($level eq "WARN") { $sConfig .= "	log4perl.logger = WARN, InfoFile, ErrorFile, Screen"; }
	elsif($level eq "ERROR") { $sConfig .= "	log4perl.logger = ERROR, InfoFile, ErrorFile, Screen"; }
	elsif($level eq "FATAL") { $sConfig .= "	log4perl.logger = FATAL, InfoFile, ErrorFile, Screen"; }
	else { printf "FATAL: Incorrect Logger Level: $level\n"; croak(); }

	# output a debug file if level = DEBUG
	if($level eq "DEBUG") {
		$sConfig .= q(

	log4perl.appender.DebugFile             = Log::Log4perl::Appender::File
	log4perl.appender.DebugFile.filename    = debug.log
	log4perl.appender.DebugFile.layout      = PatternLayout
	log4perl.appender.DebugFile.layout.ConversionPattern = %d %p> %F{1}:%L %M - %m%n );
	}

	$sConfig .= q(

	log4perl.appender.InfoFile             = Log::Log4perl::Appender::File
	log4perl.appender.InfoFile.filename    = info.log
	log4perl.appender.InfoFile.layout      = PatternLayout
	log4perl.appender.InfoFile.layout.ConversionPattern = %d %p> %F{1}:%L %M - %m%n
	log4perl.appender.InfoFile.Threshold   = INFO

	log4perl.appender.ErrorFile             = Log::Log4perl::Appender::File
	log4perl.appender.ErrorFile.filename    = error.log
	log4perl.appender.ErrorFile.layout      = PatternLayout
	log4perl.appender.ErrorFile.layout.ConversionPattern = %d %p> %F{1}:%L %M - %m%n
	log4perl.appender.ErrorFile.Threshold   = ERROR

	log4perl.appender.Screen          = Log::Log4perl::Appender::Screen
	log4perl.appender.Screen.stderr   = 0
	log4perl.appender.Screen.layout   = PatternLayout
	log4perl.appender.Screen.layout.ConversionPattern = %d %p> %F{1}:%L %M - %m%n );

	return $sConfig;
}


#==============
# END OF MODULE
#==============================================================================
1;
