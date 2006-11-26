#! /usr/bin/perl
#---------------------------------------------------------------------
# $Id$
# Copyright 2006 Christopher J. Madsen
#
# Build.PL for PostScript-Calendar
#---------------------------------------------------------------------

use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
  module_name        => 'PostScript::Calendar',
  license            => 'perl',
  dist_author        => 'Christopher J. Madsen <cjm@pobox.com>',
  dist_version_from  => 'lib/PostScript/Calendar.pm',
  requires => {
      'PostScript::File' => 1,
      'Test::More'       => 0,
  },
  create_makefile_pl => 'passthrough',
);

$builder->create_build_script();
