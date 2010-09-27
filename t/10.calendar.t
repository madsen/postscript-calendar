#! /usr/bin/perl
#---------------------------------------------------------------------
# Copyright 2010 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: 12 Mar 2010
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# Test the content of generated PostScript calendars
#---------------------------------------------------------------------

BEGIN {$ENV{TZ} = 'CST6'} # For consistent phase-of-moon calculations

use strict;
use warnings;

use FindBin '$Bin';
chdir $Bin or die "Unable to cd $Bin: $!";

use Test::More;

# Load Test::Differences, if available:
BEGIN {
  if (eval "use Test::Differences; 1") {
    # Not all versions of Test::Differences support changing the style:
    eval { Test::Differences::unified_diff() }
  } else {
    eval '*eq_or_diff = \&is;'; # Just use "is" instead
  }
} # end BEGIN

my $generateResults;

if (@ARGV and $ARGV[0] eq 'gen') {
  # Just output the actual results, so they can be diffed against this file
  $generateResults = 1;
  open(OUT, '>', '/tmp/10.calendar.t') or die $!;
  printf OUT "#%s\n\n__DATA__\n", '=' x 69;
} else {
  plan tests => 4 * 2 + 1;
}

require PostScript::Calendar;
ok(1, 'loaded PostScript::Calendar') unless $generateResults;

my $haveAstro = eval 'use Astro::MoonPhase 0.60; 1';

my ($year, $month, $name, %param, @methods);

while (<DATA>) {

  print OUT $_ if $generateResults;

  if (/^(\w+):(.+)/) {
    $param{$1} = eval $2;
    die $@ if $@;
  } # end if constructor parameter (key: value)
  elsif (/^(->.+)/) {
    push @methods, $1;
  } # end if method to call (->method(param))
  elsif ($_ eq "===\n") {
    # Read the expected results:
    my $expected = '';
    while (<DATA>) {
      last if $_ eq "---\n";
      $expected .= $_;
    }

  SKIP: {
      skip "Astro::MoonPhase not installed", 2
          if $param{phases} and not $haveAstro;

      # Run the test:
      my $cal = PostScript::Calendar->new($year, $month, %param);
      isa_ok($cal, "PostScript::Calendar", $name) unless $generateResults;

      foreach my $call (@methods) {
        eval '$cal' . $call;
        die $@ if $@;
      } # end foreach $call in @methods

      $cal->generate;
      my $got = $cal->ps_file->testable_output;

      # Remove version number:
      $got =~ s/^%%Creator: PostScript::Calendar.+\n//m;

      if ($generateResults) {
        print OUT "$got---\n";
      } else {
        eq_or_diff($got, $expected, $name);
      }
    } # end SKIP

    # Clean up:
    @methods = ();
    %param = ();
    undef $year;
    undef $month;
    undef $name;
  } # end elsif expected contents (=== ... ---)
  elsif (/^::\s*((\d{4})-(\d{2})(?!\d).*)/) {
    $name  = $1;
    $year  = $2;
    $month = $3;
  } # end elsif test name (:: name)
  else {
    die "Unrecognized line $_" if /\S/;
  }
} # end while <DATA>

#=====================================================================

__DATA__

:: 2010-02 no parameters
===
%!PS-Adobe-3.0
%%Orientation: Portrait
%%DocumentNeededResources:
%%+ font Courier-Bold Helvetica Helvetica-Oblique
%%DocumentSuppliedResources:
%%+ procset PostScript_Calendar 0 0
%%Title: (February 2010)
%%EndComments
%%BeginProlog
%%BeginResource: procset PostScript_Calendar 0 0
/pixel {72 mul 300 div} bind def % 300 dpi only
%---------------------------------------------------------------------
% Stroke a horizontal line:  WIDTH X Y hline
/hline
{
newpath
moveto
0 rlineto stroke
} bind def
%---------------------------------------------------------------------
% Stroke a vertical line:  HEIGHT X Y vline
/vline
{
newpath
moveto
0 exch rlineto stroke
} bind def
%---------------------------------------------------------------------
% Print text centered at a point:  X Y STRING showcenter
%
% Centers text horizontally
/showcenter
{
newpath
0 0 moveto
% stack X Y STRING
dup 4 1 roll                          % Put a copy of STRING on bottom
% stack STRING X Y STRING
false charpath flattenpath pathbbox   % Compute bounding box of STRING
% stack STRING X Y Lx Ly Ux Uy
pop exch pop                          % Discard Y values (... Lx Ux)
add 2 div neg                         % Compute X offset
% stack STRING X Y Ox
0                                     % Use 0 for y offset
newpath
moveto
rmoveto
show
} bind def
%---------------------------------------------------------------------
% Print left justified text:  X Y STRING showleft
%
% Does not adjust vertical placement.
/showleft
{
newpath
3 1 roll  % STRING X Y
moveto
show
} bind def
%---------------------------------------------------------------------
% Print right justified text:  X Y STRING showright
%
% Does not adjust vertical placement.
/showright
{
newpath
0 0 moveto
% stack X Y STRING
dup 4 1 roll                          % Put a copy of STRING on bottom
% stack STRING X Y STRING
false charpath flattenpath pathbbox   % Compute bounding box of STRING
% stack STRING X Y Lx Ly Ux Uy
pop exch pop                          % Discard Y values (... Lx Ux)
add neg                               % Compute X offset
% stack STRING X Y Ox
0                                     % Use 0 for y offset
newpath
moveto
rmoveto
show
} bind def
%---------------------------------------------------------------------
% Display text events:  X Y [STRING ...] Events
/Events
{
EventFont setfont
{
2 index      % stack X Y STRING X
3 -1 roll    % stack X STRING X Y
dup          % stack X STRING X Y Y
EventSpacing sub
4 1 roll     % stack X Y' STRING X Y
newpath
moveto
show
} forall
pop pop        % pop off X & Y
} bind def
%---------------------------------------------------------------------
% Fill a day rect with the current ink:
/FillDay
{
newpath
0 0 moveto
DayWidth 0 lineto
DayWidth DayHeight lineto
0 DayHeight lineto
closepath
fill
} bind def
%---------------------------------------------------------------------
% Shade a day with the default background:
/ShadeDay
{
0.85 setgray
FillDay
0 setgray
} bind def
%%EndResource
%%EndProlog
%%BeginSetup
%%EndSetup
%%Page: 1 1
%%PageBoundingBox: 24 28 588 756
%%BeginPageSetup
/pagelevel save def
userdict begin
%%EndPageSetup
0 setlinecap
0 setlinejoin
3 pixel setlinewidth
/DayHeight 138 def
/DayWidth 80 def
/TitleSize 14 def
/TitleFont /Helvetica-iso findfont TitleSize scalefont def
/LabelSize 14 def
/LabelFont /Helvetica-iso findfont LabelSize scalefont def
/DateSize 14 def
/DateFont /Helvetica-Oblique-iso findfont DateSize scalefont def
/EventSize 8 def
/EventFont /Helvetica-iso findfont EventSize scalefont def
/EventSpacing 10 def
/MiniSize 6 def
/MiniFont /Helvetica-iso findfont MiniSize scalefont def
TitleFont setfont
306 742 (February 2010) showcenter
LabelFont setfont
64 723 (Sunday) showcenter
144 723 (Monday) showcenter
224 723 (Tuesday) showcenter
304 723 (Wednesday) showcenter
384 723 (Thursday) showcenter
464 723 (Friday) showcenter
544 723 (Saturday) showcenter
DateFont setfont
180 702 (1) showright
260 702 (2) showright
340 702 (3) showright
420 702 (4) showright
500 702 (5) showright
580 702 (6) showright
100 564 (7) showright
180 564 (8) showright
260 564 (9) showright
340 564 (10) showright
420 564 (11) showright
500 564 (12) showright
580 564 (13) showright
100 426 (14) showright
180 426 (15) showright
260 426 (16) showright
340 426 (17) showright
420 426 (18) showright
500 426 (19) showright
580 426 (20) showright
100 288 (21) showright
180 288 (22) showright
260 288 (23) showright
340 288 (24) showright
420 288 (25) showright
500 288 (26) showright
580 288 (27) showright
100 150 (28) showright
166 138 718 {
560 24 3 -1 roll hline
} for
104 80 544 {
709 exch 28 vline
} for
newpath
24 737 moveto
560 0 rlineto
0 -709 rlineto
-560 0 rlineto
closepath stroke
%%PageTrailer
end
pagelevel restore
showpage
%%EOF
---


:: 2000-02 no parameters
===
%!PS-Adobe-3.0
%%Orientation: Portrait
%%DocumentNeededResources:
%%+ font Courier-Bold Helvetica Helvetica-Oblique
%%DocumentSuppliedResources:
%%+ procset PostScript_Calendar 0 0
%%Title: (February 2000)
%%EndComments
%%BeginProlog
%%BeginResource: procset PostScript_Calendar 0 0
/pixel {72 mul 300 div} bind def % 300 dpi only
%---------------------------------------------------------------------
% Stroke a horizontal line:  WIDTH X Y hline
/hline
{
newpath
moveto
0 rlineto stroke
} bind def
%---------------------------------------------------------------------
% Stroke a vertical line:  HEIGHT X Y vline
/vline
{
newpath
moveto
0 exch rlineto stroke
} bind def
%---------------------------------------------------------------------
% Print text centered at a point:  X Y STRING showcenter
%
% Centers text horizontally
/showcenter
{
newpath
0 0 moveto
% stack X Y STRING
dup 4 1 roll                          % Put a copy of STRING on bottom
% stack STRING X Y STRING
false charpath flattenpath pathbbox   % Compute bounding box of STRING
% stack STRING X Y Lx Ly Ux Uy
pop exch pop                          % Discard Y values (... Lx Ux)
add 2 div neg                         % Compute X offset
% stack STRING X Y Ox
0                                     % Use 0 for y offset
newpath
moveto
rmoveto
show
} bind def
%---------------------------------------------------------------------
% Print left justified text:  X Y STRING showleft
%
% Does not adjust vertical placement.
/showleft
{
newpath
3 1 roll  % STRING X Y
moveto
show
} bind def
%---------------------------------------------------------------------
% Print right justified text:  X Y STRING showright
%
% Does not adjust vertical placement.
/showright
{
newpath
0 0 moveto
% stack X Y STRING
dup 4 1 roll                          % Put a copy of STRING on bottom
% stack STRING X Y STRING
false charpath flattenpath pathbbox   % Compute bounding box of STRING
% stack STRING X Y Lx Ly Ux Uy
pop exch pop                          % Discard Y values (... Lx Ux)
add neg                               % Compute X offset
% stack STRING X Y Ox
0                                     % Use 0 for y offset
newpath
moveto
rmoveto
show
} bind def
%---------------------------------------------------------------------
% Display text events:  X Y [STRING ...] Events
/Events
{
EventFont setfont
{
2 index      % stack X Y STRING X
3 -1 roll    % stack X STRING X Y
dup          % stack X STRING X Y Y
EventSpacing sub
4 1 roll     % stack X Y' STRING X Y
newpath
moveto
show
} forall
pop pop        % pop off X & Y
} bind def
%---------------------------------------------------------------------
% Fill a day rect with the current ink:
/FillDay
{
newpath
0 0 moveto
DayWidth 0 lineto
DayWidth DayHeight lineto
0 DayHeight lineto
closepath
fill
} bind def
%---------------------------------------------------------------------
% Shade a day with the default background:
/ShadeDay
{
0.85 setgray
FillDay
0 setgray
} bind def
%%EndResource
%%EndProlog
%%BeginSetup
%%EndSetup
%%Page: 1 1
%%PageBoundingBox: 24 28 588 756
%%BeginPageSetup
/pagelevel save def
userdict begin
%%EndPageSetup
0 setlinecap
0 setlinejoin
3 pixel setlinewidth
/DayHeight 138 def
/DayWidth 80 def
/TitleSize 14 def
/TitleFont /Helvetica-iso findfont TitleSize scalefont def
/LabelSize 14 def
/LabelFont /Helvetica-iso findfont LabelSize scalefont def
/DateSize 14 def
/DateFont /Helvetica-Oblique-iso findfont DateSize scalefont def
/EventSize 8 def
/EventFont /Helvetica-iso findfont EventSize scalefont def
/EventSpacing 10 def
/MiniSize 6 def
/MiniFont /Helvetica-iso findfont MiniSize scalefont def
TitleFont setfont
306 742 (February 2000) showcenter
LabelFont setfont
64 723 (Sunday) showcenter
144 723 (Monday) showcenter
224 723 (Tuesday) showcenter
304 723 (Wednesday) showcenter
384 723 (Thursday) showcenter
464 723 (Friday) showcenter
544 723 (Saturday) showcenter
DateFont setfont
260 702 (1) showright
340 702 (2) showright
420 702 (3) showright
500 702 (4) showright
580 702 (5) showright
100 564 (6) showright
180 564 (7) showright
260 564 (8) showright
340 564 (9) showright
420 564 (10) showright
500 564 (11) showright
580 564 (12) showright
100 426 (13) showright
180 426 (14) showright
260 426 (15) showright
340 426 (16) showright
420 426 (17) showright
500 426 (18) showright
580 426 (19) showright
100 288 (20) showright
180 288 (21) showright
260 288 (22) showright
340 288 (23) showright
420 288 (24) showright
500 288 (25) showright
580 288 (26) showright
100 150 (27) showright
180 150 (28) showright
260 150 (29) showright
166 138 718 {
560 24 3 -1 roll hline
} for
104 80 544 {
709 exch 28 vline
} for
newpath
24 737 moveto
560 0 rlineto
0 -709 rlineto
-560 0 rlineto
closepath stroke
%%PageTrailer
end
pagelevel restore
showpage
%%EOF
---

:: 2008-07 holiday
shade_days_of_week: [ 0, 6 ]
->add_event(4, 'Independence day');
->shade(4);
===
%!PS-Adobe-3.0
%%Orientation: Portrait
%%DocumentNeededResources:
%%+ font Courier-Bold Helvetica Helvetica-Oblique
%%DocumentSuppliedResources:
%%+ procset PostScript_Calendar 0 0
%%Title: (July 2008)
%%EndComments
%%BeginProlog
%%BeginResource: procset PostScript_Calendar 0 0
/pixel {72 mul 300 div} bind def % 300 dpi only
%---------------------------------------------------------------------
% Stroke a horizontal line:  WIDTH X Y hline
/hline
{
newpath
moveto
0 rlineto stroke
} bind def
%---------------------------------------------------------------------
% Stroke a vertical line:  HEIGHT X Y vline
/vline
{
newpath
moveto
0 exch rlineto stroke
} bind def
%---------------------------------------------------------------------
% Print text centered at a point:  X Y STRING showcenter
%
% Centers text horizontally
/showcenter
{
newpath
0 0 moveto
% stack X Y STRING
dup 4 1 roll                          % Put a copy of STRING on bottom
% stack STRING X Y STRING
false charpath flattenpath pathbbox   % Compute bounding box of STRING
% stack STRING X Y Lx Ly Ux Uy
pop exch pop                          % Discard Y values (... Lx Ux)
add 2 div neg                         % Compute X offset
% stack STRING X Y Ox
0                                     % Use 0 for y offset
newpath
moveto
rmoveto
show
} bind def
%---------------------------------------------------------------------
% Print left justified text:  X Y STRING showleft
%
% Does not adjust vertical placement.
/showleft
{
newpath
3 1 roll  % STRING X Y
moveto
show
} bind def
%---------------------------------------------------------------------
% Print right justified text:  X Y STRING showright
%
% Does not adjust vertical placement.
/showright
{
newpath
0 0 moveto
% stack X Y STRING
dup 4 1 roll                          % Put a copy of STRING on bottom
% stack STRING X Y STRING
false charpath flattenpath pathbbox   % Compute bounding box of STRING
% stack STRING X Y Lx Ly Ux Uy
pop exch pop                          % Discard Y values (... Lx Ux)
add neg                               % Compute X offset
% stack STRING X Y Ox
0                                     % Use 0 for y offset
newpath
moveto
rmoveto
show
} bind def
%---------------------------------------------------------------------
% Display text events:  X Y [STRING ...] Events
/Events
{
EventFont setfont
{
2 index      % stack X Y STRING X
3 -1 roll    % stack X STRING X Y
dup          % stack X STRING X Y Y
EventSpacing sub
4 1 roll     % stack X Y' STRING X Y
newpath
moveto
show
} forall
pop pop        % pop off X & Y
} bind def
%---------------------------------------------------------------------
% Fill a day rect with the current ink:
/FillDay
{
newpath
0 0 moveto
DayWidth 0 lineto
DayWidth DayHeight lineto
0 DayHeight lineto
closepath
fill
} bind def
%---------------------------------------------------------------------
% Shade a day with the default background:
/ShadeDay
{
0.85 setgray
FillDay
0 setgray
} bind def
%%EndResource
%%EndProlog
%%BeginSetup
%%EndSetup
%%Page: 1 1
%%PageBoundingBox: 24 28 588 756
%%BeginPageSetup
/pagelevel save def
userdict begin
%%EndPageSetup
0 setlinecap
0 setlinejoin
3 pixel setlinewidth
/DayHeight 138 def
/DayWidth 80 def
/TitleSize 14 def
/TitleFont /Helvetica-iso findfont TitleSize scalefont def
/LabelSize 14 def
/LabelFont /Helvetica-iso findfont LabelSize scalefont def
/DateSize 14 def
/DateFont /Helvetica-Oblique-iso findfont DateSize scalefont def
/EventSize 8 def
/EventFont /Helvetica-iso findfont EventSize scalefont def
/EventSpacing 10 def
/MiniSize 6 def
/MiniFont /Helvetica-iso findfont MiniSize scalefont def
gsave
424 580 translate
ShadeDay
grestore
427 708 [(Independence)
(day)] Events
gsave
504 580 translate
ShadeDay
grestore
gsave
24 442 translate
ShadeDay
grestore
gsave
504 442 translate
ShadeDay
grestore
gsave
24 304 translate
ShadeDay
grestore
gsave
504 304 translate
ShadeDay
grestore
gsave
24 166 translate
ShadeDay
grestore
gsave
504 166 translate
ShadeDay
grestore
gsave
24 28 translate
ShadeDay
grestore
TitleFont setfont
306 742 (July 2008) showcenter
LabelFont setfont
64 723 (Sunday) showcenter
144 723 (Monday) showcenter
224 723 (Tuesday) showcenter
304 723 (Wednesday) showcenter
384 723 (Thursday) showcenter
464 723 (Friday) showcenter
544 723 (Saturday) showcenter
DateFont setfont
260 702 (1) showright
340 702 (2) showright
420 702 (3) showright
500 702 (4) showright
580 702 (5) showright
100 564 (6) showright
180 564 (7) showright
260 564 (8) showright
340 564 (9) showright
420 564 (10) showright
500 564 (11) showright
580 564 (12) showright
100 426 (13) showright
180 426 (14) showright
260 426 (15) showright
340 426 (16) showright
420 426 (17) showright
500 426 (18) showright
580 426 (19) showright
100 288 (20) showright
180 288 (21) showright
260 288 (22) showright
340 288 (23) showright
420 288 (24) showright
500 288 (25) showright
580 288 (26) showright
100 150 (27) showright
180 150 (28) showright
260 150 (29) showright
340 150 (30) showright
420 150 (31) showright
166 138 718 {
560 24 3 -1 roll hline
} for
104 80 544 {
709 exch 28 vline
} for
newpath
24 737 moveto
560 0 rlineto
0 -709 rlineto
-560 0 rlineto
closepath stroke
%%PageTrailer
end
pagelevel restore
showpage
%%EOF
---

:: 2010-11 moon phases
phases: 1
->add_event(25, "Thanksgiving");
->add_event(11, "Veteran\'s Day");
===
%!PS-Adobe-3.0
%%Orientation: Portrait
%%DocumentNeededResources:
%%+ font Courier-Bold Helvetica Helvetica-Oblique
%%DocumentSuppliedResources:
%%+ procset PostScript_Calendar 0 0
%%+ procset PostScript_Calendar_Moon 0 0
%%Title: (November 2010)
%%EndComments
%%BeginProlog
%%BeginResource: procset PostScript_Calendar 0 0
/pixel {72 mul 300 div} bind def % 300 dpi only
%---------------------------------------------------------------------
% Stroke a horizontal line:  WIDTH X Y hline
/hline
{
newpath
moveto
0 rlineto stroke
} bind def
%---------------------------------------------------------------------
% Stroke a vertical line:  HEIGHT X Y vline
/vline
{
newpath
moveto
0 exch rlineto stroke
} bind def
%---------------------------------------------------------------------
% Print text centered at a point:  X Y STRING showcenter
%
% Centers text horizontally
/showcenter
{
newpath
0 0 moveto
% stack X Y STRING
dup 4 1 roll                          % Put a copy of STRING on bottom
% stack STRING X Y STRING
false charpath flattenpath pathbbox   % Compute bounding box of STRING
% stack STRING X Y Lx Ly Ux Uy
pop exch pop                          % Discard Y values (... Lx Ux)
add 2 div neg                         % Compute X offset
% stack STRING X Y Ox
0                                     % Use 0 for y offset
newpath
moveto
rmoveto
show
} bind def
%---------------------------------------------------------------------
% Print left justified text:  X Y STRING showleft
%
% Does not adjust vertical placement.
/showleft
{
newpath
3 1 roll  % STRING X Y
moveto
show
} bind def
%---------------------------------------------------------------------
% Print right justified text:  X Y STRING showright
%
% Does not adjust vertical placement.
/showright
{
newpath
0 0 moveto
% stack X Y STRING
dup 4 1 roll                          % Put a copy of STRING on bottom
% stack STRING X Y STRING
false charpath flattenpath pathbbox   % Compute bounding box of STRING
% stack STRING X Y Lx Ly Ux Uy
pop exch pop                          % Discard Y values (... Lx Ux)
add neg                               % Compute X offset
% stack STRING X Y Ox
0                                     % Use 0 for y offset
newpath
moveto
rmoveto
show
} bind def
%---------------------------------------------------------------------
% Display text events:  X Y [STRING ...] Events
/Events
{
EventFont setfont
{
2 index      % stack X Y STRING X
3 -1 roll    % stack X STRING X Y
dup          % stack X STRING X Y Y
EventSpacing sub
4 1 roll     % stack X Y' STRING X Y
newpath
moveto
show
} forall
pop pop        % pop off X & Y
} bind def
%---------------------------------------------------------------------
% Fill a day rect with the current ink:
/FillDay
{
newpath
0 0 moveto
DayWidth 0 lineto
DayWidth DayHeight lineto
0 DayHeight lineto
closepath
fill
} bind def
%---------------------------------------------------------------------
% Shade a day with the default background:
/ShadeDay
{
0.85 setgray
FillDay
0 setgray
} bind def
%%EndResource
%%BeginResource: procset PostScript_Calendar_Moon 0 0
%---------------------------------------------------------------------
% Show the phase of the moon:  PHASE ShowPhase
/ShowPhase
{
newpath
MoonMargin DateSize 2 div add
DayHeight MoonMargin sub
DateSize 2 div sub
DateSize 2 div
0 360 arc
closepath
cvx exec
} bind def
/NewMoon { fill } bind def
/FullMoon { gsave 1 setgray fill grestore stroke } bind def
/FirstQuarter
{
FullMoon
newpath
MoonMargin DateSize 2 div add
DayHeight MoonMargin sub DateSize 2 div sub
DateSize 2 div
90 270 arc
closepath fill
} bind def
/LastQuarter
{
FullMoon
newpath
MoonMargin DateSize 2 div add
DayHeight MoonMargin sub DateSize 2 div sub
DateSize 2 div
270 90 arc
closepath fill
} bind def
%%EndResource
%%EndProlog
%%BeginSetup
%%EndSetup
%%Page: 1 1
%%PageBoundingBox: 24 28 588 756
%%BeginPageSetup
/pagelevel save def
userdict begin
%%EndPageSetup
0 setlinecap
0 setlinejoin
3 pixel setlinewidth
/DayHeight 138 def
/DayWidth 80 def
/TitleSize 14 def
/TitleFont /Helvetica-iso findfont TitleSize scalefont def
/LabelSize 14 def
/LabelFont /Helvetica-iso findfont LabelSize scalefont def
/DateSize 14 def
/DateFont /Helvetica-Oblique-iso findfont DateSize scalefont def
/EventSize 8 def
/EventFont /Helvetica-iso findfont EventSize scalefont def
/EventSpacing 10 def
/MiniSize 6 def
/MiniFont /Helvetica-iso findfont MiniSize scalefont def
/MoonMargin 6 def
gsave
424 580 translate
/NewMoon ShowPhase
grestore
347 570 [(Veteran's Day)] Events
gsave
504 442 translate
/FirstQuarter ShowPhase
grestore
gsave
24 166 translate
/FullMoon ShowPhase
grestore
347 294 [(Thanksgiving)] Events
gsave
24 28 translate
/LastQuarter ShowPhase
grestore
TitleFont setfont
306 742 (November 2010) showcenter
LabelFont setfont
64 723 (Sunday) showcenter
144 723 (Monday) showcenter
224 723 (Tuesday) showcenter
304 723 (Wednesday) showcenter
384 723 (Thursday) showcenter
464 723 (Friday) showcenter
544 723 (Saturday) showcenter
DateFont setfont
180 702 (1) showright
260 702 (2) showright
340 702 (3) showright
420 702 (4) showright
500 702 (5) showright
580 702 (6) showright
100 564 (7) showright
180 564 (8) showright
260 564 (9) showright
340 564 (10) showright
420 564 (11) showright
500 564 (12) showright
580 564 (13) showright
100 426 (14) showright
180 426 (15) showright
260 426 (16) showright
340 426 (17) showright
420 426 (18) showright
500 426 (19) showright
580 426 (20) showright
100 288 (21) showright
180 288 (22) showright
260 288 (23) showright
340 288 (24) showright
420 288 (25) showright
500 288 (26) showright
580 288 (27) showright
100 150 (28) showright
180 150 (29) showright
260 150 (30) showright
166 138 718 {
560 24 3 -1 roll hline
} for
104 80 544 {
709 exch 28 vline
} for
newpath
24 737 moveto
560 0 rlineto
0 -709 rlineto
-560 0 rlineto
closepath stroke
%%PageTrailer
end
pagelevel restore
showpage
%%EOF
---
