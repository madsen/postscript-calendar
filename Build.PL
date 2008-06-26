#! /usr/bin/perl
#---------------------------------------------------------------------
# $Id$
# Copyright 2006 Christopher J. Madsen
#
# Build.PL for PostScript-Calendar
#---------------------------------------------------------------------

use strict;
use warnings;

# Make sure we're using My_Build from our distribution:
use FindBin;
use lib "$FindBin::Bin/tools";

use My_Build;          # Our customized version of Module::Build

my $builder = My_Build->new(
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
      'FindBin'          => 0,
      'Module::Build'    => '0.21',
      'Test::More'       => 0,
  },
  create_makefile_pl => 'passthrough',
  dynamic_config     => 0,
  meta_merge         => { no_index  => { directory => [ 'tools' ] }},
);

$builder->create_build_script();
