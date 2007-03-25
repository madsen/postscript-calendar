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
  dist_author        => 'Christopher J. Madsen <perl@cjmweb.net>',
  dist_version_from  => 'lib/PostScript/Calendar.pm',
  requires => {
      'perl'             => '5.6.0',
      'Date::Calc'       => '5.0',
      'Font::AFM'        => 1,
      'PostScript::File' => 1,
  },
  recommends => {
      'Astro::MoonPhase' => '0.60',
  },
  build_requires => {
      'Module::Build'  => 0.21,
      'Test::More'     => 0,
  },
  create_makefile_pl => 'passthrough',
  dynamic_config     => 0,
);

$builder->create_build_script();
