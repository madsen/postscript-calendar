#---------------------------------------------------------------------
# $Id$
package My_Build;
#
# Copyright 2007 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: 18 Feb 2007
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# Customize Module::Build for PostScript::Calendar
#---------------------------------------------------------------------

use strict;
use File::Spec ();
use base 'Module::Build';

#=====================================================================
# Package Global Variables:

our $VERSION = '0.01';

#=====================================================================

sub prereq_failures
{
  my $self = shift @_;

  my $out = $self->SUPER::prereq_failures(@_);

  return $out unless $out;

  if (my $attrib = $out->{recommends}{'Astro::MoonPhase'}) {
    $attrib->{message} .= <<"END Astro::MoonPhase";
\n
   Astro::MoonPhase is only required if you want to display the phase
   of the moon on your calendars.  You need at least version 0.60.

   If you install Astro::MoonPhase later, you do NOT need to
   re-install PostScript::Calendar.
END Astro::MoonPhase
  } # end if Astro::MoonPhase failed

  return $out;
} # end prereq_failures

#---------------------------------------------------------------------
sub ACTION_distdir
{
  my $self = shift @_;

  $self->SUPER::ACTION_distdir(@_);

  # Process README, inserting version number & removing comments:

  my $out = File::Spec->catfile($self->dist_dir, 'README');
  my @stat = stat($out) or die;

  unlink $out or die;

  open(IN,  '<', 'README') or die;
  open(OUT, '>', $out)     or die;

  while (<IN>) {
    next if /^\$\$/;            # $$ indicates comment
    s/\$\%v\%\$/ $self->dist_version /ge;

    print OUT $_;
  } # end while IN

  close IN;
  close OUT;

  utime @stat[8,9], $out;       # Restore modification times
  chmod $stat[2],   $out;       # Restore access permissions
} # end ACTION_distdir

#=====================================================================
# Package Return Value:

1;
