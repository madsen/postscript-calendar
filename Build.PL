#! /usr/bin/perl
#---------------------------------------------------------------------
# Build.PL for PostScript-Calendar
#
# Copyright 2010 Christopher J. Madsen
#
#---------------------------------------------------------------------

use strict;
use warnings;

use inc::My_Build;          # Our customized version of Module::Build

my $builder = inc::My_Build->new(
  module_name        => 'PostScript::Calendar',
  license            => 'perl',
  dist_author        => 'Christopher J. Madsen <perl@cjmweb.net>',
  dist_version_from  => 'lib/PostScript/Calendar.pm',
  dynamic_config     => 0,
  # Prerequisites inserted by DistZilla:
##{ $plugin->get_prereqs ##}
);

$builder->create_build_script();
