#! /usr/bin/perl
#---------------------------------------------------------------------
# Copyright 2010 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: 27 Sep 2010
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# Test creating a single file with an entire year's calendar pages
#---------------------------------------------------------------------

use strict;
use warnings;

use Test::More 0.88;            # done_testing

# Load Test::Differences, if available:
BEGIN {
  # RECOMMEND PREREQ: Test::Differences
  if (eval "use Test::Differences; 1") {
    # Not all versions of Test::Differences support changing the style:
    eval { Test::Differences::unified_diff() }
  } else {
    eval '*eq_or_diff = \&is;'; # Just use "is" instead
  }
} # end BEGIN

my $generateResults = '';

if (@ARGV and $ARGV[0] eq 'gen') {
  # Just output the actual results, so they can be diffed against this file
  $generateResults = 1;
  open(OUT, '>', '/tmp/20.yearly.t') or die $!;
} elsif (@ARGV and $ARGV[0] eq 'ps') {
  $generateResults = 'ps';
  open(OUT, '>', '/tmp/20.yearly.ps') or die $!;
} else {
  plan tests => 14;
}

#---------------------------------------------------------------------
require PostScript::Calendar;

my $ps;
for my $month (1 .. 12) {
  $ps->newpage if $ps;
  my $cal = PostScript::Calendar->new(2010, $month, ps_file => $ps,
                                      day_height => 96,
                                      mini_calendars => 'before');
  isa_ok($cal, 'PostScript::Calendar') unless $generateResults;
  $cal->generate;
  # We get the PostScript::File from the first calendar,
  # and pass that to the remaining calendars:
  $ps ||= $cal->ps_file;
} # end for $month 1 to 12

isa_ok($ps, 'PostScript::File') unless $generateResults;

# Use sanitized output (unless $generateResults eq 'ps'):
my $out = $ps->testable_output($generateResults eq 'ps');

$out =~ s/(?<=^%%Creator: PostScript::Calendar).+(?=\n)//m;

if ($generateResults) {
  print OUT $out;
} else {
  eq_or_diff($out, <<'END CALENDAR', 'generated PostScript');
%!PS-Adobe-3.0
%%Creator: PostScript::Calendar
%%Orientation: Portrait
%%DocumentNeededResources:
%%+ font Courier-Bold Helvetica Helvetica-Oblique
%%DocumentSuppliedResources:
%%+ procset PostScript_Calendar 0 0
%%Title: (January 2010)
%%Pages: 12
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
/DayHeight 96 def
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
MiniFont setfont
64 708 (December) showcenter
31.25 699 (S) showcenter
42.125 699 (M) showcenter
53 699 (T) showcenter
63.875 699 (W) showcenter
74.75 699 (T) showcenter
85.625 699 (F) showcenter
96.5 699 (S) showcenter
53 690 (1) showcenter
63.875 690 (2) showcenter
74.75 690 (3) showcenter
85.625 690 (4) showcenter
96.5 690 (5) showcenter
31.25 681 (6) showcenter
42.125 681 (7) showcenter
53 681 (8) showcenter
63.875 681 (9) showcenter
74.75 681 (10) showcenter
85.625 681 (11) showcenter
96.5 681 (12) showcenter
31.25 672 (13) showcenter
42.125 672 (14) showcenter
53 672 (15) showcenter
63.875 672 (16) showcenter
74.75 672 (17) showcenter
85.625 672 (18) showcenter
96.5 672 (19) showcenter
31.25 663 (20) showcenter
42.125 663 (21) showcenter
53 663 (22) showcenter
63.875 663 (23) showcenter
74.75 663 (24) showcenter
85.625 663 (25) showcenter
96.5 663 (26) showcenter
31.25 654 (27) showcenter
42.125 654 (28) showcenter
53 654 (29) showcenter
63.875 654 (30) showcenter
74.75 654 (31) showcenter
MiniFont setfont
144 708 (February) showcenter
111.25 699 (S) showcenter
122.125 699 (M) showcenter
133 699 (T) showcenter
143.875 699 (W) showcenter
154.75 699 (T) showcenter
165.625 699 (F) showcenter
176.5 699 (S) showcenter
122.125 690 (1) showcenter
133 690 (2) showcenter
143.875 690 (3) showcenter
154.75 690 (4) showcenter
165.625 690 (5) showcenter
176.5 690 (6) showcenter
111.25 681 (7) showcenter
122.125 681 (8) showcenter
133 681 (9) showcenter
143.875 681 (10) showcenter
154.75 681 (11) showcenter
165.625 681 (12) showcenter
176.5 681 (13) showcenter
111.25 672 (14) showcenter
122.125 672 (15) showcenter
133 672 (16) showcenter
143.875 672 (17) showcenter
154.75 672 (18) showcenter
165.625 672 (19) showcenter
176.5 672 (20) showcenter
111.25 663 (21) showcenter
122.125 663 (22) showcenter
133 663 (23) showcenter
143.875 663 (24) showcenter
154.75 663 (25) showcenter
165.625 663 (26) showcenter
176.5 663 (27) showcenter
111.25 654 (28) showcenter
TitleFont setfont
306 742 (January 2010) showcenter
LabelFont setfont
64 723 (Sunday) showcenter
144 723 (Monday) showcenter
224 723 (Tuesday) showcenter
304 723 (Wednesday) showcenter
384 723 (Thursday) showcenter
464 723 (Friday) showcenter
544 723 (Saturday) showcenter
DateFont setfont
500 702 (1) showright
580 702 (2) showright
100 606 (3) showright
180 606 (4) showright
260 606 (5) showright
340 606 (6) showright
420 606 (7) showright
500 606 (8) showright
580 606 (9) showright
100 510 (10) showright
180 510 (11) showright
260 510 (12) showright
340 510 (13) showright
420 510 (14) showright
500 510 (15) showright
580 510 (16) showright
100 414 (17) showright
180 414 (18) showright
260 414 (19) showright
340 414 (20) showright
420 414 (21) showright
500 414 (22) showright
580 414 (23) showright
100 318 (24) showright
180 318 (25) showright
260 318 (26) showright
340 318 (27) showright
420 318 (28) showright
500 318 (29) showright
580 318 (30) showright
100 222 (31) showright
238 96 718 {
560 24 3 -1 roll hline
} for
104 80 544 {
595 exch 142 vline
} for
newpath
24 737 moveto
560 0 rlineto
0 -595 rlineto
-560 0 rlineto
closepath stroke
%%PageTrailer
end
pagelevel restore
showpage
%%Page: 2 2
%%PageBoundingBox: 24 28 588 756
%%BeginPageSetup
/pagelevel save def
userdict begin
%%EndPageSetup
0 setlinecap
0 setlinejoin
3 pixel setlinewidth
/DayHeight 96 def
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
MiniFont setfont
464 324 (January) showcenter
431.25 315 (S) showcenter
442.125 315 (M) showcenter
453 315 (T) showcenter
463.875 315 (W) showcenter
474.75 315 (T) showcenter
485.625 315 (F) showcenter
496.5 315 (S) showcenter
485.625 306 (1) showcenter
496.5 306 (2) showcenter
431.25 297 (3) showcenter
442.125 297 (4) showcenter
453 297 (5) showcenter
463.875 297 (6) showcenter
474.75 297 (7) showcenter
485.625 297 (8) showcenter
496.5 297 (9) showcenter
431.25 288 (10) showcenter
442.125 288 (11) showcenter
453 288 (12) showcenter
463.875 288 (13) showcenter
474.75 288 (14) showcenter
485.625 288 (15) showcenter
496.5 288 (16) showcenter
431.25 279 (17) showcenter
442.125 279 (18) showcenter
453 279 (19) showcenter
463.875 279 (20) showcenter
474.75 279 (21) showcenter
485.625 279 (22) showcenter
496.5 279 (23) showcenter
431.25 270 (24) showcenter
442.125 270 (25) showcenter
453 270 (26) showcenter
463.875 270 (27) showcenter
474.75 270 (28) showcenter
485.625 270 (29) showcenter
496.5 270 (30) showcenter
431.25 261 (31) showcenter
MiniFont setfont
544 324 (March) showcenter
511.25 315 (S) showcenter
522.125 315 (M) showcenter
533 315 (T) showcenter
543.875 315 (W) showcenter
554.75 315 (T) showcenter
565.625 315 (F) showcenter
576.5 315 (S) showcenter
522.125 306 (1) showcenter
533 306 (2) showcenter
543.875 306 (3) showcenter
554.75 306 (4) showcenter
565.625 306 (5) showcenter
576.5 306 (6) showcenter
511.25 297 (7) showcenter
522.125 297 (8) showcenter
533 297 (9) showcenter
543.875 297 (10) showcenter
554.75 297 (11) showcenter
565.625 297 (12) showcenter
576.5 297 (13) showcenter
511.25 288 (14) showcenter
522.125 288 (15) showcenter
533 288 (16) showcenter
543.875 288 (17) showcenter
554.75 288 (18) showcenter
565.625 288 (19) showcenter
576.5 288 (20) showcenter
511.25 279 (21) showcenter
522.125 279 (22) showcenter
533 279 (23) showcenter
543.875 279 (24) showcenter
554.75 279 (25) showcenter
565.625 279 (26) showcenter
576.5 279 (27) showcenter
511.25 270 (28) showcenter
522.125 270 (29) showcenter
533 270 (30) showcenter
543.875 270 (31) showcenter
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
100 606 (7) showright
180 606 (8) showright
260 606 (9) showright
340 606 (10) showright
420 606 (11) showright
500 606 (12) showright
580 606 (13) showright
100 510 (14) showright
180 510 (15) showright
260 510 (16) showright
340 510 (17) showright
420 510 (18) showright
500 510 (19) showright
580 510 (20) showright
100 414 (21) showright
180 414 (22) showright
260 414 (23) showright
340 414 (24) showright
420 414 (25) showright
500 414 (26) showright
580 414 (27) showright
100 318 (28) showright
334 96 718 {
560 24 3 -1 roll hline
} for
104 80 544 {
499 exch 238 vline
} for
newpath
24 737 moveto
560 0 rlineto
0 -499 rlineto
-560 0 rlineto
closepath stroke
%%PageTrailer
end
pagelevel restore
showpage
%%Page: 3 3
%%PageBoundingBox: 24 28 588 756
%%BeginPageSetup
/pagelevel save def
userdict begin
%%EndPageSetup
0 setlinecap
0 setlinejoin
3 pixel setlinewidth
/DayHeight 96 def
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
MiniFont setfont
464 324 (February) showcenter
431.25 315 (S) showcenter
442.125 315 (M) showcenter
453 315 (T) showcenter
463.875 315 (W) showcenter
474.75 315 (T) showcenter
485.625 315 (F) showcenter
496.5 315 (S) showcenter
442.125 306 (1) showcenter
453 306 (2) showcenter
463.875 306 (3) showcenter
474.75 306 (4) showcenter
485.625 306 (5) showcenter
496.5 306 (6) showcenter
431.25 297 (7) showcenter
442.125 297 (8) showcenter
453 297 (9) showcenter
463.875 297 (10) showcenter
474.75 297 (11) showcenter
485.625 297 (12) showcenter
496.5 297 (13) showcenter
431.25 288 (14) showcenter
442.125 288 (15) showcenter
453 288 (16) showcenter
463.875 288 (17) showcenter
474.75 288 (18) showcenter
485.625 288 (19) showcenter
496.5 288 (20) showcenter
431.25 279 (21) showcenter
442.125 279 (22) showcenter
453 279 (23) showcenter
463.875 279 (24) showcenter
474.75 279 (25) showcenter
485.625 279 (26) showcenter
496.5 279 (27) showcenter
431.25 270 (28) showcenter
MiniFont setfont
544 324 (April) showcenter
511.25 315 (S) showcenter
522.125 315 (M) showcenter
533 315 (T) showcenter
543.875 315 (W) showcenter
554.75 315 (T) showcenter
565.625 315 (F) showcenter
576.5 315 (S) showcenter
554.75 306 (1) showcenter
565.625 306 (2) showcenter
576.5 306 (3) showcenter
511.25 297 (4) showcenter
522.125 297 (5) showcenter
533 297 (6) showcenter
543.875 297 (7) showcenter
554.75 297 (8) showcenter
565.625 297 (9) showcenter
576.5 297 (10) showcenter
511.25 288 (11) showcenter
522.125 288 (12) showcenter
533 288 (13) showcenter
543.875 288 (14) showcenter
554.75 288 (15) showcenter
565.625 288 (16) showcenter
576.5 288 (17) showcenter
511.25 279 (18) showcenter
522.125 279 (19) showcenter
533 279 (20) showcenter
543.875 279 (21) showcenter
554.75 279 (22) showcenter
565.625 279 (23) showcenter
576.5 279 (24) showcenter
511.25 270 (25) showcenter
522.125 270 (26) showcenter
533 270 (27) showcenter
543.875 270 (28) showcenter
554.75 270 (29) showcenter
565.625 270 (30) showcenter
TitleFont setfont
306 742 (March 2010) showcenter
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
100 606 (7) showright
180 606 (8) showright
260 606 (9) showright
340 606 (10) showright
420 606 (11) showright
500 606 (12) showright
580 606 (13) showright
100 510 (14) showright
180 510 (15) showright
260 510 (16) showright
340 510 (17) showright
420 510 (18) showright
500 510 (19) showright
580 510 (20) showright
100 414 (21) showright
180 414 (22) showright
260 414 (23) showright
340 414 (24) showright
420 414 (25) showright
500 414 (26) showright
580 414 (27) showright
100 318 (28) showright
180 318 (29) showright
260 318 (30) showright
340 318 (31) showright
334 96 718 {
560 24 3 -1 roll hline
} for
104 80 544 {
499 exch 238 vline
} for
newpath
24 737 moveto
560 0 rlineto
0 -499 rlineto
-560 0 rlineto
closepath stroke
%%PageTrailer
end
pagelevel restore
showpage
%%Page: 4 4
%%PageBoundingBox: 24 28 588 756
%%BeginPageSetup
/pagelevel save def
userdict begin
%%EndPageSetup
0 setlinecap
0 setlinejoin
3 pixel setlinewidth
/DayHeight 96 def
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
MiniFont setfont
64 708 (March) showcenter
31.25 699 (S) showcenter
42.125 699 (M) showcenter
53 699 (T) showcenter
63.875 699 (W) showcenter
74.75 699 (T) showcenter
85.625 699 (F) showcenter
96.5 699 (S) showcenter
42.125 690 (1) showcenter
53 690 (2) showcenter
63.875 690 (3) showcenter
74.75 690 (4) showcenter
85.625 690 (5) showcenter
96.5 690 (6) showcenter
31.25 681 (7) showcenter
42.125 681 (8) showcenter
53 681 (9) showcenter
63.875 681 (10) showcenter
74.75 681 (11) showcenter
85.625 681 (12) showcenter
96.5 681 (13) showcenter
31.25 672 (14) showcenter
42.125 672 (15) showcenter
53 672 (16) showcenter
63.875 672 (17) showcenter
74.75 672 (18) showcenter
85.625 672 (19) showcenter
96.5 672 (20) showcenter
31.25 663 (21) showcenter
42.125 663 (22) showcenter
53 663 (23) showcenter
63.875 663 (24) showcenter
74.75 663 (25) showcenter
85.625 663 (26) showcenter
96.5 663 (27) showcenter
31.25 654 (28) showcenter
42.125 654 (29) showcenter
53 654 (30) showcenter
63.875 654 (31) showcenter
MiniFont setfont
144 708 (May) showcenter
111.25 699 (S) showcenter
122.125 699 (M) showcenter
133 699 (T) showcenter
143.875 699 (W) showcenter
154.75 699 (T) showcenter
165.625 699 (F) showcenter
176.5 699 (S) showcenter
176.5 690 (1) showcenter
111.25 681 (2) showcenter
122.125 681 (3) showcenter
133 681 (4) showcenter
143.875 681 (5) showcenter
154.75 681 (6) showcenter
165.625 681 (7) showcenter
176.5 681 (8) showcenter
111.25 672 (9) showcenter
122.125 672 (10) showcenter
133 672 (11) showcenter
143.875 672 (12) showcenter
154.75 672 (13) showcenter
165.625 672 (14) showcenter
176.5 672 (15) showcenter
111.25 663 (16) showcenter
122.125 663 (17) showcenter
133 663 (18) showcenter
143.875 663 (19) showcenter
154.75 663 (20) showcenter
165.625 663 (21) showcenter
176.5 663 (22) showcenter
111.25 654 (23) showcenter
122.125 654 (24) showcenter
133 654 (25) showcenter
143.875 654 (26) showcenter
154.75 654 (27) showcenter
165.625 654 (28) showcenter
176.5 654 (29) showcenter
111.25 645 (30) showcenter
122.125 645 (31) showcenter
TitleFont setfont
306 742 (April 2010) showcenter
LabelFont setfont
64 723 (Sunday) showcenter
144 723 (Monday) showcenter
224 723 (Tuesday) showcenter
304 723 (Wednesday) showcenter
384 723 (Thursday) showcenter
464 723 (Friday) showcenter
544 723 (Saturday) showcenter
DateFont setfont
420 702 (1) showright
500 702 (2) showright
580 702 (3) showright
100 606 (4) showright
180 606 (5) showright
260 606 (6) showright
340 606 (7) showright
420 606 (8) showright
500 606 (9) showright
580 606 (10) showright
100 510 (11) showright
180 510 (12) showright
260 510 (13) showright
340 510 (14) showright
420 510 (15) showright
500 510 (16) showright
580 510 (17) showright
100 414 (18) showright
180 414 (19) showright
260 414 (20) showright
340 414 (21) showright
420 414 (22) showright
500 414 (23) showright
580 414 (24) showright
100 318 (25) showright
180 318 (26) showright
260 318 (27) showright
340 318 (28) showright
420 318 (29) showright
500 318 (30) showright
334 96 718 {
560 24 3 -1 roll hline
} for
104 80 544 {
499 exch 238 vline
} for
newpath
24 737 moveto
560 0 rlineto
0 -499 rlineto
-560 0 rlineto
closepath stroke
%%PageTrailer
end
pagelevel restore
showpage
%%Page: 5 5
%%PageBoundingBox: 24 28 588 756
%%BeginPageSetup
/pagelevel save def
userdict begin
%%EndPageSetup
0 setlinecap
0 setlinejoin
3 pixel setlinewidth
/DayHeight 96 def
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
MiniFont setfont
64 708 (April) showcenter
31.25 699 (S) showcenter
42.125 699 (M) showcenter
53 699 (T) showcenter
63.875 699 (W) showcenter
74.75 699 (T) showcenter
85.625 699 (F) showcenter
96.5 699 (S) showcenter
74.75 690 (1) showcenter
85.625 690 (2) showcenter
96.5 690 (3) showcenter
31.25 681 (4) showcenter
42.125 681 (5) showcenter
53 681 (6) showcenter
63.875 681 (7) showcenter
74.75 681 (8) showcenter
85.625 681 (9) showcenter
96.5 681 (10) showcenter
31.25 672 (11) showcenter
42.125 672 (12) showcenter
53 672 (13) showcenter
63.875 672 (14) showcenter
74.75 672 (15) showcenter
85.625 672 (16) showcenter
96.5 672 (17) showcenter
31.25 663 (18) showcenter
42.125 663 (19) showcenter
53 663 (20) showcenter
63.875 663 (21) showcenter
74.75 663 (22) showcenter
85.625 663 (23) showcenter
96.5 663 (24) showcenter
31.25 654 (25) showcenter
42.125 654 (26) showcenter
53 654 (27) showcenter
63.875 654 (28) showcenter
74.75 654 (29) showcenter
85.625 654 (30) showcenter
MiniFont setfont
144 708 (June) showcenter
111.25 699 (S) showcenter
122.125 699 (M) showcenter
133 699 (T) showcenter
143.875 699 (W) showcenter
154.75 699 (T) showcenter
165.625 699 (F) showcenter
176.5 699 (S) showcenter
133 690 (1) showcenter
143.875 690 (2) showcenter
154.75 690 (3) showcenter
165.625 690 (4) showcenter
176.5 690 (5) showcenter
111.25 681 (6) showcenter
122.125 681 (7) showcenter
133 681 (8) showcenter
143.875 681 (9) showcenter
154.75 681 (10) showcenter
165.625 681 (11) showcenter
176.5 681 (12) showcenter
111.25 672 (13) showcenter
122.125 672 (14) showcenter
133 672 (15) showcenter
143.875 672 (16) showcenter
154.75 672 (17) showcenter
165.625 672 (18) showcenter
176.5 672 (19) showcenter
111.25 663 (20) showcenter
122.125 663 (21) showcenter
133 663 (22) showcenter
143.875 663 (23) showcenter
154.75 663 (24) showcenter
165.625 663 (25) showcenter
176.5 663 (26) showcenter
111.25 654 (27) showcenter
122.125 654 (28) showcenter
133 654 (29) showcenter
143.875 654 (30) showcenter
TitleFont setfont
306 742 (May 2010) showcenter
LabelFont setfont
64 723 (Sunday) showcenter
144 723 (Monday) showcenter
224 723 (Tuesday) showcenter
304 723 (Wednesday) showcenter
384 723 (Thursday) showcenter
464 723 (Friday) showcenter
544 723 (Saturday) showcenter
DateFont setfont
580 702 (1) showright
100 606 (2) showright
180 606 (3) showright
260 606 (4) showright
340 606 (5) showright
420 606 (6) showright
500 606 (7) showright
580 606 (8) showright
100 510 (9) showright
180 510 (10) showright
260 510 (11) showright
340 510 (12) showright
420 510 (13) showright
500 510 (14) showright
580 510 (15) showright
100 414 (16) showright
180 414 (17) showright
260 414 (18) showright
340 414 (19) showright
420 414 (20) showright
500 414 (21) showright
580 414 (22) showright
100 318 (23) showright
180 318 (24) showright
260 318 (25) showright
340 318 (26) showright
420 318 (27) showright
500 318 (28) showright
580 318 (29) showright
100 222 (30) showright
180 222 (31) showright
238 96 718 {
560 24 3 -1 roll hline
} for
104 80 544 {
595 exch 142 vline
} for
newpath
24 737 moveto
560 0 rlineto
0 -595 rlineto
-560 0 rlineto
closepath stroke
%%PageTrailer
end
pagelevel restore
showpage
%%Page: 6 6
%%PageBoundingBox: 24 28 588 756
%%BeginPageSetup
/pagelevel save def
userdict begin
%%EndPageSetup
0 setlinecap
0 setlinejoin
3 pixel setlinewidth
/DayHeight 96 def
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
MiniFont setfont
64 708 (May) showcenter
31.25 699 (S) showcenter
42.125 699 (M) showcenter
53 699 (T) showcenter
63.875 699 (W) showcenter
74.75 699 (T) showcenter
85.625 699 (F) showcenter
96.5 699 (S) showcenter
96.5 690 (1) showcenter
31.25 681 (2) showcenter
42.125 681 (3) showcenter
53 681 (4) showcenter
63.875 681 (5) showcenter
74.75 681 (6) showcenter
85.625 681 (7) showcenter
96.5 681 (8) showcenter
31.25 672 (9) showcenter
42.125 672 (10) showcenter
53 672 (11) showcenter
63.875 672 (12) showcenter
74.75 672 (13) showcenter
85.625 672 (14) showcenter
96.5 672 (15) showcenter
31.25 663 (16) showcenter
42.125 663 (17) showcenter
53 663 (18) showcenter
63.875 663 (19) showcenter
74.75 663 (20) showcenter
85.625 663 (21) showcenter
96.5 663 (22) showcenter
31.25 654 (23) showcenter
42.125 654 (24) showcenter
53 654 (25) showcenter
63.875 654 (26) showcenter
74.75 654 (27) showcenter
85.625 654 (28) showcenter
96.5 654 (29) showcenter
31.25 645 (30) showcenter
42.125 645 (31) showcenter
MiniFont setfont
144 708 (July) showcenter
111.25 699 (S) showcenter
122.125 699 (M) showcenter
133 699 (T) showcenter
143.875 699 (W) showcenter
154.75 699 (T) showcenter
165.625 699 (F) showcenter
176.5 699 (S) showcenter
154.75 690 (1) showcenter
165.625 690 (2) showcenter
176.5 690 (3) showcenter
111.25 681 (4) showcenter
122.125 681 (5) showcenter
133 681 (6) showcenter
143.875 681 (7) showcenter
154.75 681 (8) showcenter
165.625 681 (9) showcenter
176.5 681 (10) showcenter
111.25 672 (11) showcenter
122.125 672 (12) showcenter
133 672 (13) showcenter
143.875 672 (14) showcenter
154.75 672 (15) showcenter
165.625 672 (16) showcenter
176.5 672 (17) showcenter
111.25 663 (18) showcenter
122.125 663 (19) showcenter
133 663 (20) showcenter
143.875 663 (21) showcenter
154.75 663 (22) showcenter
165.625 663 (23) showcenter
176.5 663 (24) showcenter
111.25 654 (25) showcenter
122.125 654 (26) showcenter
133 654 (27) showcenter
143.875 654 (28) showcenter
154.75 654 (29) showcenter
165.625 654 (30) showcenter
176.5 654 (31) showcenter
TitleFont setfont
306 742 (June 2010) showcenter
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
100 606 (6) showright
180 606 (7) showright
260 606 (8) showright
340 606 (9) showright
420 606 (10) showright
500 606 (11) showright
580 606 (12) showright
100 510 (13) showright
180 510 (14) showright
260 510 (15) showright
340 510 (16) showright
420 510 (17) showright
500 510 (18) showright
580 510 (19) showright
100 414 (20) showright
180 414 (21) showright
260 414 (22) showright
340 414 (23) showright
420 414 (24) showright
500 414 (25) showright
580 414 (26) showright
100 318 (27) showright
180 318 (28) showright
260 318 (29) showright
340 318 (30) showright
334 96 718 {
560 24 3 -1 roll hline
} for
104 80 544 {
499 exch 238 vline
} for
newpath
24 737 moveto
560 0 rlineto
0 -499 rlineto
-560 0 rlineto
closepath stroke
%%PageTrailer
end
pagelevel restore
showpage
%%Page: 7 7
%%PageBoundingBox: 24 28 588 756
%%BeginPageSetup
/pagelevel save def
userdict begin
%%EndPageSetup
0 setlinecap
0 setlinejoin
3 pixel setlinewidth
/DayHeight 96 def
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
MiniFont setfont
64 708 (June) showcenter
31.25 699 (S) showcenter
42.125 699 (M) showcenter
53 699 (T) showcenter
63.875 699 (W) showcenter
74.75 699 (T) showcenter
85.625 699 (F) showcenter
96.5 699 (S) showcenter
53 690 (1) showcenter
63.875 690 (2) showcenter
74.75 690 (3) showcenter
85.625 690 (4) showcenter
96.5 690 (5) showcenter
31.25 681 (6) showcenter
42.125 681 (7) showcenter
53 681 (8) showcenter
63.875 681 (9) showcenter
74.75 681 (10) showcenter
85.625 681 (11) showcenter
96.5 681 (12) showcenter
31.25 672 (13) showcenter
42.125 672 (14) showcenter
53 672 (15) showcenter
63.875 672 (16) showcenter
74.75 672 (17) showcenter
85.625 672 (18) showcenter
96.5 672 (19) showcenter
31.25 663 (20) showcenter
42.125 663 (21) showcenter
53 663 (22) showcenter
63.875 663 (23) showcenter
74.75 663 (24) showcenter
85.625 663 (25) showcenter
96.5 663 (26) showcenter
31.25 654 (27) showcenter
42.125 654 (28) showcenter
53 654 (29) showcenter
63.875 654 (30) showcenter
MiniFont setfont
144 708 (August) showcenter
111.25 699 (S) showcenter
122.125 699 (M) showcenter
133 699 (T) showcenter
143.875 699 (W) showcenter
154.75 699 (T) showcenter
165.625 699 (F) showcenter
176.5 699 (S) showcenter
111.25 690 (1) showcenter
122.125 690 (2) showcenter
133 690 (3) showcenter
143.875 690 (4) showcenter
154.75 690 (5) showcenter
165.625 690 (6) showcenter
176.5 690 (7) showcenter
111.25 681 (8) showcenter
122.125 681 (9) showcenter
133 681 (10) showcenter
143.875 681 (11) showcenter
154.75 681 (12) showcenter
165.625 681 (13) showcenter
176.5 681 (14) showcenter
111.25 672 (15) showcenter
122.125 672 (16) showcenter
133 672 (17) showcenter
143.875 672 (18) showcenter
154.75 672 (19) showcenter
165.625 672 (20) showcenter
176.5 672 (21) showcenter
111.25 663 (22) showcenter
122.125 663 (23) showcenter
133 663 (24) showcenter
143.875 663 (25) showcenter
154.75 663 (26) showcenter
165.625 663 (27) showcenter
176.5 663 (28) showcenter
111.25 654 (29) showcenter
122.125 654 (30) showcenter
133 654 (31) showcenter
TitleFont setfont
306 742 (July 2010) showcenter
LabelFont setfont
64 723 (Sunday) showcenter
144 723 (Monday) showcenter
224 723 (Tuesday) showcenter
304 723 (Wednesday) showcenter
384 723 (Thursday) showcenter
464 723 (Friday) showcenter
544 723 (Saturday) showcenter
DateFont setfont
420 702 (1) showright
500 702 (2) showright
580 702 (3) showright
100 606 (4) showright
180 606 (5) showright
260 606 (6) showright
340 606 (7) showright
420 606 (8) showright
500 606 (9) showright
580 606 (10) showright
100 510 (11) showright
180 510 (12) showright
260 510 (13) showright
340 510 (14) showright
420 510 (15) showright
500 510 (16) showright
580 510 (17) showright
100 414 (18) showright
180 414 (19) showright
260 414 (20) showright
340 414 (21) showright
420 414 (22) showright
500 414 (23) showright
580 414 (24) showright
100 318 (25) showright
180 318 (26) showright
260 318 (27) showright
340 318 (28) showright
420 318 (29) showright
500 318 (30) showright
580 318 (31) showright
334 96 718 {
560 24 3 -1 roll hline
} for
104 80 544 {
499 exch 238 vline
} for
newpath
24 737 moveto
560 0 rlineto
0 -499 rlineto
-560 0 rlineto
closepath stroke
%%PageTrailer
end
pagelevel restore
showpage
%%Page: 8 8
%%PageBoundingBox: 24 28 588 756
%%BeginPageSetup
/pagelevel save def
userdict begin
%%EndPageSetup
0 setlinecap
0 setlinejoin
3 pixel setlinewidth
/DayHeight 96 def
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
MiniFont setfont
464 324 (July) showcenter
431.25 315 (S) showcenter
442.125 315 (M) showcenter
453 315 (T) showcenter
463.875 315 (W) showcenter
474.75 315 (T) showcenter
485.625 315 (F) showcenter
496.5 315 (S) showcenter
474.75 306 (1) showcenter
485.625 306 (2) showcenter
496.5 306 (3) showcenter
431.25 297 (4) showcenter
442.125 297 (5) showcenter
453 297 (6) showcenter
463.875 297 (7) showcenter
474.75 297 (8) showcenter
485.625 297 (9) showcenter
496.5 297 (10) showcenter
431.25 288 (11) showcenter
442.125 288 (12) showcenter
453 288 (13) showcenter
463.875 288 (14) showcenter
474.75 288 (15) showcenter
485.625 288 (16) showcenter
496.5 288 (17) showcenter
431.25 279 (18) showcenter
442.125 279 (19) showcenter
453 279 (20) showcenter
463.875 279 (21) showcenter
474.75 279 (22) showcenter
485.625 279 (23) showcenter
496.5 279 (24) showcenter
431.25 270 (25) showcenter
442.125 270 (26) showcenter
453 270 (27) showcenter
463.875 270 (28) showcenter
474.75 270 (29) showcenter
485.625 270 (30) showcenter
496.5 270 (31) showcenter
MiniFont setfont
544 324 (September) showcenter
511.25 315 (S) showcenter
522.125 315 (M) showcenter
533 315 (T) showcenter
543.875 315 (W) showcenter
554.75 315 (T) showcenter
565.625 315 (F) showcenter
576.5 315 (S) showcenter
543.875 306 (1) showcenter
554.75 306 (2) showcenter
565.625 306 (3) showcenter
576.5 306 (4) showcenter
511.25 297 (5) showcenter
522.125 297 (6) showcenter
533 297 (7) showcenter
543.875 297 (8) showcenter
554.75 297 (9) showcenter
565.625 297 (10) showcenter
576.5 297 (11) showcenter
511.25 288 (12) showcenter
522.125 288 (13) showcenter
533 288 (14) showcenter
543.875 288 (15) showcenter
554.75 288 (16) showcenter
565.625 288 (17) showcenter
576.5 288 (18) showcenter
511.25 279 (19) showcenter
522.125 279 (20) showcenter
533 279 (21) showcenter
543.875 279 (22) showcenter
554.75 279 (23) showcenter
565.625 279 (24) showcenter
576.5 279 (25) showcenter
511.25 270 (26) showcenter
522.125 270 (27) showcenter
533 270 (28) showcenter
543.875 270 (29) showcenter
554.75 270 (30) showcenter
TitleFont setfont
306 742 (August 2010) showcenter
LabelFont setfont
64 723 (Sunday) showcenter
144 723 (Monday) showcenter
224 723 (Tuesday) showcenter
304 723 (Wednesday) showcenter
384 723 (Thursday) showcenter
464 723 (Friday) showcenter
544 723 (Saturday) showcenter
DateFont setfont
100 702 (1) showright
180 702 (2) showright
260 702 (3) showright
340 702 (4) showright
420 702 (5) showright
500 702 (6) showright
580 702 (7) showright
100 606 (8) showright
180 606 (9) showright
260 606 (10) showright
340 606 (11) showright
420 606 (12) showright
500 606 (13) showright
580 606 (14) showright
100 510 (15) showright
180 510 (16) showright
260 510 (17) showright
340 510 (18) showright
420 510 (19) showright
500 510 (20) showright
580 510 (21) showright
100 414 (22) showright
180 414 (23) showright
260 414 (24) showright
340 414 (25) showright
420 414 (26) showright
500 414 (27) showright
580 414 (28) showright
100 318 (29) showright
180 318 (30) showright
260 318 (31) showright
334 96 718 {
560 24 3 -1 roll hline
} for
104 80 544 {
499 exch 238 vline
} for
newpath
24 737 moveto
560 0 rlineto
0 -499 rlineto
-560 0 rlineto
closepath stroke
%%PageTrailer
end
pagelevel restore
showpage
%%Page: 9 9
%%PageBoundingBox: 24 28 588 756
%%BeginPageSetup
/pagelevel save def
userdict begin
%%EndPageSetup
0 setlinecap
0 setlinejoin
3 pixel setlinewidth
/DayHeight 96 def
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
MiniFont setfont
64 708 (August) showcenter
31.25 699 (S) showcenter
42.125 699 (M) showcenter
53 699 (T) showcenter
63.875 699 (W) showcenter
74.75 699 (T) showcenter
85.625 699 (F) showcenter
96.5 699 (S) showcenter
31.25 690 (1) showcenter
42.125 690 (2) showcenter
53 690 (3) showcenter
63.875 690 (4) showcenter
74.75 690 (5) showcenter
85.625 690 (6) showcenter
96.5 690 (7) showcenter
31.25 681 (8) showcenter
42.125 681 (9) showcenter
53 681 (10) showcenter
63.875 681 (11) showcenter
74.75 681 (12) showcenter
85.625 681 (13) showcenter
96.5 681 (14) showcenter
31.25 672 (15) showcenter
42.125 672 (16) showcenter
53 672 (17) showcenter
63.875 672 (18) showcenter
74.75 672 (19) showcenter
85.625 672 (20) showcenter
96.5 672 (21) showcenter
31.25 663 (22) showcenter
42.125 663 (23) showcenter
53 663 (24) showcenter
63.875 663 (25) showcenter
74.75 663 (26) showcenter
85.625 663 (27) showcenter
96.5 663 (28) showcenter
31.25 654 (29) showcenter
42.125 654 (30) showcenter
53 654 (31) showcenter
MiniFont setfont
144 708 (October) showcenter
111.25 699 (S) showcenter
122.125 699 (M) showcenter
133 699 (T) showcenter
143.875 699 (W) showcenter
154.75 699 (T) showcenter
165.625 699 (F) showcenter
176.5 699 (S) showcenter
165.625 690 (1) showcenter
176.5 690 (2) showcenter
111.25 681 (3) showcenter
122.125 681 (4) showcenter
133 681 (5) showcenter
143.875 681 (6) showcenter
154.75 681 (7) showcenter
165.625 681 (8) showcenter
176.5 681 (9) showcenter
111.25 672 (10) showcenter
122.125 672 (11) showcenter
133 672 (12) showcenter
143.875 672 (13) showcenter
154.75 672 (14) showcenter
165.625 672 (15) showcenter
176.5 672 (16) showcenter
111.25 663 (17) showcenter
122.125 663 (18) showcenter
133 663 (19) showcenter
143.875 663 (20) showcenter
154.75 663 (21) showcenter
165.625 663 (22) showcenter
176.5 663 (23) showcenter
111.25 654 (24) showcenter
122.125 654 (25) showcenter
133 654 (26) showcenter
143.875 654 (27) showcenter
154.75 654 (28) showcenter
165.625 654 (29) showcenter
176.5 654 (30) showcenter
111.25 645 (31) showcenter
TitleFont setfont
306 742 (September 2010) showcenter
LabelFont setfont
64 723 (Sunday) showcenter
144 723 (Monday) showcenter
224 723 (Tuesday) showcenter
304 723 (Wednesday) showcenter
384 723 (Thursday) showcenter
464 723 (Friday) showcenter
544 723 (Saturday) showcenter
DateFont setfont
340 702 (1) showright
420 702 (2) showright
500 702 (3) showright
580 702 (4) showright
100 606 (5) showright
180 606 (6) showright
260 606 (7) showright
340 606 (8) showright
420 606 (9) showright
500 606 (10) showright
580 606 (11) showright
100 510 (12) showright
180 510 (13) showright
260 510 (14) showright
340 510 (15) showright
420 510 (16) showright
500 510 (17) showright
580 510 (18) showright
100 414 (19) showright
180 414 (20) showright
260 414 (21) showright
340 414 (22) showright
420 414 (23) showright
500 414 (24) showright
580 414 (25) showright
100 318 (26) showright
180 318 (27) showright
260 318 (28) showright
340 318 (29) showright
420 318 (30) showright
334 96 718 {
560 24 3 -1 roll hline
} for
104 80 544 {
499 exch 238 vline
} for
newpath
24 737 moveto
560 0 rlineto
0 -499 rlineto
-560 0 rlineto
closepath stroke
%%PageTrailer
end
pagelevel restore
showpage
%%Page: 10 10
%%PageBoundingBox: 24 28 588 756
%%BeginPageSetup
/pagelevel save def
userdict begin
%%EndPageSetup
0 setlinecap
0 setlinejoin
3 pixel setlinewidth
/DayHeight 96 def
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
MiniFont setfont
64 708 (September) showcenter
31.25 699 (S) showcenter
42.125 699 (M) showcenter
53 699 (T) showcenter
63.875 699 (W) showcenter
74.75 699 (T) showcenter
85.625 699 (F) showcenter
96.5 699 (S) showcenter
63.875 690 (1) showcenter
74.75 690 (2) showcenter
85.625 690 (3) showcenter
96.5 690 (4) showcenter
31.25 681 (5) showcenter
42.125 681 (6) showcenter
53 681 (7) showcenter
63.875 681 (8) showcenter
74.75 681 (9) showcenter
85.625 681 (10) showcenter
96.5 681 (11) showcenter
31.25 672 (12) showcenter
42.125 672 (13) showcenter
53 672 (14) showcenter
63.875 672 (15) showcenter
74.75 672 (16) showcenter
85.625 672 (17) showcenter
96.5 672 (18) showcenter
31.25 663 (19) showcenter
42.125 663 (20) showcenter
53 663 (21) showcenter
63.875 663 (22) showcenter
74.75 663 (23) showcenter
85.625 663 (24) showcenter
96.5 663 (25) showcenter
31.25 654 (26) showcenter
42.125 654 (27) showcenter
53 654 (28) showcenter
63.875 654 (29) showcenter
74.75 654 (30) showcenter
MiniFont setfont
144 708 (November) showcenter
111.25 699 (S) showcenter
122.125 699 (M) showcenter
133 699 (T) showcenter
143.875 699 (W) showcenter
154.75 699 (T) showcenter
165.625 699 (F) showcenter
176.5 699 (S) showcenter
122.125 690 (1) showcenter
133 690 (2) showcenter
143.875 690 (3) showcenter
154.75 690 (4) showcenter
165.625 690 (5) showcenter
176.5 690 (6) showcenter
111.25 681 (7) showcenter
122.125 681 (8) showcenter
133 681 (9) showcenter
143.875 681 (10) showcenter
154.75 681 (11) showcenter
165.625 681 (12) showcenter
176.5 681 (13) showcenter
111.25 672 (14) showcenter
122.125 672 (15) showcenter
133 672 (16) showcenter
143.875 672 (17) showcenter
154.75 672 (18) showcenter
165.625 672 (19) showcenter
176.5 672 (20) showcenter
111.25 663 (21) showcenter
122.125 663 (22) showcenter
133 663 (23) showcenter
143.875 663 (24) showcenter
154.75 663 (25) showcenter
165.625 663 (26) showcenter
176.5 663 (27) showcenter
111.25 654 (28) showcenter
122.125 654 (29) showcenter
133 654 (30) showcenter
TitleFont setfont
306 742 (October 2010) showcenter
LabelFont setfont
64 723 (Sunday) showcenter
144 723 (Monday) showcenter
224 723 (Tuesday) showcenter
304 723 (Wednesday) showcenter
384 723 (Thursday) showcenter
464 723 (Friday) showcenter
544 723 (Saturday) showcenter
DateFont setfont
500 702 (1) showright
580 702 (2) showright
100 606 (3) showright
180 606 (4) showright
260 606 (5) showright
340 606 (6) showright
420 606 (7) showright
500 606 (8) showright
580 606 (9) showright
100 510 (10) showright
180 510 (11) showright
260 510 (12) showright
340 510 (13) showright
420 510 (14) showright
500 510 (15) showright
580 510 (16) showright
100 414 (17) showright
180 414 (18) showright
260 414 (19) showright
340 414 (20) showright
420 414 (21) showright
500 414 (22) showright
580 414 (23) showright
100 318 (24) showright
180 318 (25) showright
260 318 (26) showright
340 318 (27) showright
420 318 (28) showright
500 318 (29) showright
580 318 (30) showright
100 222 (31) showright
238 96 718 {
560 24 3 -1 roll hline
} for
104 80 544 {
595 exch 142 vline
} for
newpath
24 737 moveto
560 0 rlineto
0 -595 rlineto
-560 0 rlineto
closepath stroke
%%PageTrailer
end
pagelevel restore
showpage
%%Page: 11 11
%%PageBoundingBox: 24 28 588 756
%%BeginPageSetup
/pagelevel save def
userdict begin
%%EndPageSetup
0 setlinecap
0 setlinejoin
3 pixel setlinewidth
/DayHeight 96 def
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
MiniFont setfont
464 324 (October) showcenter
431.25 315 (S) showcenter
442.125 315 (M) showcenter
453 315 (T) showcenter
463.875 315 (W) showcenter
474.75 315 (T) showcenter
485.625 315 (F) showcenter
496.5 315 (S) showcenter
485.625 306 (1) showcenter
496.5 306 (2) showcenter
431.25 297 (3) showcenter
442.125 297 (4) showcenter
453 297 (5) showcenter
463.875 297 (6) showcenter
474.75 297 (7) showcenter
485.625 297 (8) showcenter
496.5 297 (9) showcenter
431.25 288 (10) showcenter
442.125 288 (11) showcenter
453 288 (12) showcenter
463.875 288 (13) showcenter
474.75 288 (14) showcenter
485.625 288 (15) showcenter
496.5 288 (16) showcenter
431.25 279 (17) showcenter
442.125 279 (18) showcenter
453 279 (19) showcenter
463.875 279 (20) showcenter
474.75 279 (21) showcenter
485.625 279 (22) showcenter
496.5 279 (23) showcenter
431.25 270 (24) showcenter
442.125 270 (25) showcenter
453 270 (26) showcenter
463.875 270 (27) showcenter
474.75 270 (28) showcenter
485.625 270 (29) showcenter
496.5 270 (30) showcenter
431.25 261 (31) showcenter
MiniFont setfont
544 324 (December) showcenter
511.25 315 (S) showcenter
522.125 315 (M) showcenter
533 315 (T) showcenter
543.875 315 (W) showcenter
554.75 315 (T) showcenter
565.625 315 (F) showcenter
576.5 315 (S) showcenter
543.875 306 (1) showcenter
554.75 306 (2) showcenter
565.625 306 (3) showcenter
576.5 306 (4) showcenter
511.25 297 (5) showcenter
522.125 297 (6) showcenter
533 297 (7) showcenter
543.875 297 (8) showcenter
554.75 297 (9) showcenter
565.625 297 (10) showcenter
576.5 297 (11) showcenter
511.25 288 (12) showcenter
522.125 288 (13) showcenter
533 288 (14) showcenter
543.875 288 (15) showcenter
554.75 288 (16) showcenter
565.625 288 (17) showcenter
576.5 288 (18) showcenter
511.25 279 (19) showcenter
522.125 279 (20) showcenter
533 279 (21) showcenter
543.875 279 (22) showcenter
554.75 279 (23) showcenter
565.625 279 (24) showcenter
576.5 279 (25) showcenter
511.25 270 (26) showcenter
522.125 270 (27) showcenter
533 270 (28) showcenter
543.875 270 (29) showcenter
554.75 270 (30) showcenter
565.625 270 (31) showcenter
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
100 606 (7) showright
180 606 (8) showright
260 606 (9) showright
340 606 (10) showright
420 606 (11) showright
500 606 (12) showright
580 606 (13) showright
100 510 (14) showright
180 510 (15) showright
260 510 (16) showright
340 510 (17) showright
420 510 (18) showright
500 510 (19) showright
580 510 (20) showright
100 414 (21) showright
180 414 (22) showright
260 414 (23) showright
340 414 (24) showright
420 414 (25) showright
500 414 (26) showright
580 414 (27) showright
100 318 (28) showright
180 318 (29) showright
260 318 (30) showright
334 96 718 {
560 24 3 -1 roll hline
} for
104 80 544 {
499 exch 238 vline
} for
newpath
24 737 moveto
560 0 rlineto
0 -499 rlineto
-560 0 rlineto
closepath stroke
%%PageTrailer
end
pagelevel restore
showpage
%%Page: 12 12
%%PageBoundingBox: 24 28 588 756
%%BeginPageSetup
/pagelevel save def
userdict begin
%%EndPageSetup
0 setlinecap
0 setlinejoin
3 pixel setlinewidth
/DayHeight 96 def
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
MiniFont setfont
64 708 (November) showcenter
31.25 699 (S) showcenter
42.125 699 (M) showcenter
53 699 (T) showcenter
63.875 699 (W) showcenter
74.75 699 (T) showcenter
85.625 699 (F) showcenter
96.5 699 (S) showcenter
42.125 690 (1) showcenter
53 690 (2) showcenter
63.875 690 (3) showcenter
74.75 690 (4) showcenter
85.625 690 (5) showcenter
96.5 690 (6) showcenter
31.25 681 (7) showcenter
42.125 681 (8) showcenter
53 681 (9) showcenter
63.875 681 (10) showcenter
74.75 681 (11) showcenter
85.625 681 (12) showcenter
96.5 681 (13) showcenter
31.25 672 (14) showcenter
42.125 672 (15) showcenter
53 672 (16) showcenter
63.875 672 (17) showcenter
74.75 672 (18) showcenter
85.625 672 (19) showcenter
96.5 672 (20) showcenter
31.25 663 (21) showcenter
42.125 663 (22) showcenter
53 663 (23) showcenter
63.875 663 (24) showcenter
74.75 663 (25) showcenter
85.625 663 (26) showcenter
96.5 663 (27) showcenter
31.25 654 (28) showcenter
42.125 654 (29) showcenter
53 654 (30) showcenter
MiniFont setfont
144 708 (January) showcenter
111.25 699 (S) showcenter
122.125 699 (M) showcenter
133 699 (T) showcenter
143.875 699 (W) showcenter
154.75 699 (T) showcenter
165.625 699 (F) showcenter
176.5 699 (S) showcenter
176.5 690 (1) showcenter
111.25 681 (2) showcenter
122.125 681 (3) showcenter
133 681 (4) showcenter
143.875 681 (5) showcenter
154.75 681 (6) showcenter
165.625 681 (7) showcenter
176.5 681 (8) showcenter
111.25 672 (9) showcenter
122.125 672 (10) showcenter
133 672 (11) showcenter
143.875 672 (12) showcenter
154.75 672 (13) showcenter
165.625 672 (14) showcenter
176.5 672 (15) showcenter
111.25 663 (16) showcenter
122.125 663 (17) showcenter
133 663 (18) showcenter
143.875 663 (19) showcenter
154.75 663 (20) showcenter
165.625 663 (21) showcenter
176.5 663 (22) showcenter
111.25 654 (23) showcenter
122.125 654 (24) showcenter
133 654 (25) showcenter
143.875 654 (26) showcenter
154.75 654 (27) showcenter
165.625 654 (28) showcenter
176.5 654 (29) showcenter
111.25 645 (30) showcenter
122.125 645 (31) showcenter
TitleFont setfont
306 742 (December 2010) showcenter
LabelFont setfont
64 723 (Sunday) showcenter
144 723 (Monday) showcenter
224 723 (Tuesday) showcenter
304 723 (Wednesday) showcenter
384 723 (Thursday) showcenter
464 723 (Friday) showcenter
544 723 (Saturday) showcenter
DateFont setfont
340 702 (1) showright
420 702 (2) showright
500 702 (3) showright
580 702 (4) showright
100 606 (5) showright
180 606 (6) showright
260 606 (7) showright
340 606 (8) showright
420 606 (9) showright
500 606 (10) showright
580 606 (11) showright
100 510 (12) showright
180 510 (13) showright
260 510 (14) showright
340 510 (15) showright
420 510 (16) showright
500 510 (17) showright
580 510 (18) showright
100 414 (19) showright
180 414 (20) showright
260 414 (21) showright
340 414 (22) showright
420 414 (23) showright
500 414 (24) showright
580 414 (25) showright
100 318 (26) showright
180 318 (27) showright
260 318 (28) showright
340 318 (29) showright
420 318 (30) showright
500 318 (31) showright
334 96 718 {
560 24 3 -1 roll hline
} for
104 80 544 {
499 exch 238 vline
} for
newpath
24 737 moveto
560 0 rlineto
0 -499 rlineto
-560 0 rlineto
closepath stroke
%%PageTrailer
end
pagelevel restore
showpage
%%EOF
END CALENDAR

  done_testing();
} # end else running the test
