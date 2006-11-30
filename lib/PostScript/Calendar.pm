#---------------------------------------------------------------------
package PostScript::Calendar;
#
# Copyright 2006 Christopher J. Madsen
#
# Author: Christopher J. Madsen <cjm@pobox.com>
# Created: Sat Nov 25 14:32:55 2006
# $Id$
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# Generate a PostScript calendar
#---------------------------------------------------------------------

use 5.006;
use warnings;
use strict;
use Carp;
use Date::Calc qw(Add_Delta_YM Day_of_Week Day_of_Week_to_Text
                  Days_in_Month Localtime Mktime Month_to_Text);
use Font::AFM;

#=====================================================================
# Package Global Variables:

our $VERSION = '0.01';

our @phaseName = qw(NewMoon FirstQuarter FullMoon LastQuarter);

#---------------------------------------------------------------------
# Tied hashes for interpolating function calls into strings:

{ package PostScript::Calendar::Interpolation;

  sub TIEHASH { bless $_[1], $_[0] }
  sub FETCH   { $_[0]->($_[1]) }
} # end PostScript::Calendar::Interpolation

our (%E, %S);
tie %E, 'PostScript::Calendar::Interpolation', sub { $_[0] }; # eval
tie %S, 'PostScript::Calendar::Interpolation', \&psstring;    # quoted string

#---------------------------------------------------------------------
# Create a properly quoted PostScript string:

my %special = (
  "\n" => '\n', "\r" => '\r', "\t" => '\t', "\b" => '\b',
  "\f" => '\f', "\\" => '\\', "("  => '\(', ")"  => '\)',
);
my $specialKeys = join '', keys %special;

sub psstring
{
  my $string = $_[0];
  $string =~ s/([$specialKeys])/$special{$1}/go;
  "($string)";
} # end psstring

#---------------------------------------------------------------------
# Return the first defined value:

sub firstdef
{
  foreach (@_) {
    return $_ if defined $_;
  }

  $_[-1];
} # end firstdef

#---------------------------------------------------------------------
# Add delta months:
#
# ($year, $month) = Add_Delta_M($year, $month, $delta_months);

sub Add_Delta_M
{
  (Add_Delta_YM($_[0], $_[1], 1, 0, $_[2]))[0,1];
}

#=====================================================================
# Constants:
#---------------------------------------------------------------------

sub evTxt () { 0 }
sub evPS  () { 1 }
sub evBackground () { 2 }
sub evTopMargin  () { 3 }

#=====================================================================
# Package PostScript::Calendar:

sub new
{
  my ($class, $year, $month, %p) = @_;

  my $self = bless {
    events    => [],
    psFile    => $p{ps_file},
    condense  => $p{condense},
    border    => $p{border},
    dayHeight => $p{day_height},
    mini      => $p{mini_calendars},
    phases    => $p{phases},
    title     => ($p{title} || sprintf '%s %d', Month_to_Text($month), $year),
    days      => ($p{days} || [ 0 .. 6 ]), # Sun .. Sat
    year      => $year,
    month     => $month,
    sideMar   => firstdef($p{side_margins},  24),
    topMar    => firstdef($p{top_margin},    36),
    botMar    => firstdef($p{bottom_margin}, 24),
    titleFont => $p{title_font} || 'Helvetica-iso',
    titleSize => $p{title_size} || 14,
    titleSkip => firstdef($p{title_skip}, 5),
    labelFont => $p{label_font} || $p{title_font} || 'Helvetica-iso',
    labelSize => $p{label_size} || $p{title_size} || 14,
    labelSkip => firstdef($p{label_skip}, $p{title_skip}, 5),
    dateFont  => $p{date_font} || 'Helvetica-Oblique-iso',
    dateSize  => $p{date_size} || $p{title_size} || 14,
    eventFont => $p{event_font} || 'Helvetica-iso',
    eventSize => $p{event_size} || 8,
    eventSkip => firstdef($p{event_skip}, 2),
    miniFont  => $p{mini_font} || 'Helvetica-iso',
    miniSize  => $p{mini_size} || 7,
    dateRightMar => firstdef($p{date_right_margin}, 4),
    dateTopMar   => firstdef($p{date_top_margin},   2),
    eventTopMar   => firstdef($p{event_top_margin},   $p{event_margin}, 2),
    eventLeftMar  => firstdef($p{event_left_margin},  $p{event_margin}, 3),
    eventRightMar => firstdef($p{event_right_margin}, $p{event_margin}, 2),
    moonMargin    => firstdef($p{moon_margin}, 6),
  }, $class;

  my $days     = $self->{days};
  my $firstDay = $days->[0];
  $self->{dayOffsets} = [ map { $_ - $firstDay } @$days ];

  $self->{dayNames} =
      ($p{day_names} or
       [ map { Day_of_Week_to_Text($_ % 7 || 7) } @$days ]);

  unless ($self->{psFile}) {
    require PostScript::File;
    $self->{psFile} = PostScript::File->new(
      paper       => ($p{paper} || 'Letter'),
      top         => $self->{topMar},
      left        => $self->{sideMar},
      right       => $self->{sideMar},
      reencode    => 'ISOLatin1Encoding',
      font_suffix => '-iso',
      landscape   => $p{landscape},
    );
  }

  $self;
} # end new

#---------------------------------------------------------------------
sub calc_moon_phases
{
  my ($self, $year, $month) = @_;

  require Astro::MoonPhase;
  Astro::MoonPhase->VERSION(0.60); # Need phaselist

  my ($phase, @dates) = Astro::MoonPhase::phaselist(
    Mktime($year, $month, 1, 0,0,0),
    Mktime(Add_Delta_M($year, $month, 1), 1, 0,0,0)
  );

  # Convert Unix times to day-of-month:
  ($phase, map { (Localtime $_)[2] } @dates);
} # end calc_moon_phases

#---------------------------------------------------------------------
sub compute_grid
{
  my ($self, $year, $month, $condense) = @_;

  my ($days, $offsets) = @$self{qw(days dayOffsets)};

  my $numDays = Days_in_Month($year, $month);

  my @grid;

  my $leftDate = 1 + $days->[0] - Day_of_Week($year, $month, 1);

  $leftDate += 7 if $leftDate + $offsets->[-1] < 1;

  while ($leftDate <= $numDays) {
    push @grid, [ map { my $d = $leftDate + $_;
                        ($d > 0 and $d <= $numDays) ? $d : undef } @$offsets ];
    $leftDate += 7;
  }

  if ($condense and @grid == 6) {
    if ($grid[0][-2]) { # merge up the bottom row
      $grid[-2][0] = [ split => $grid[-2][0], $grid[-1][0] ];
      pop @grid;
    } else { # merge down the top row
      $grid[1][-1] = [ split => $grid[0][-1], $grid[1][-1] ];
      shift @grid;
    }
  } # end if grid needs to be condensed

  return \@grid;
} # end compute_grid

#---------------------------------------------------------------------
sub add_event
{
  my ($self, $date, $message) = @_;

  push @{$self->{events}[$date][evTxt]}, $message;
} # end add_event

#---------------------------------------------------------------------
sub shade
{
  my $self = shift @_;

  my $events = $self->{events};

  while (@_) {
    $events->[shift @_][evBackground] = "ShadeDay";
  }
} # end shade

#---------------------------------------------------------------------
sub shade_days_of_week
{
  my $self = shift @_;

  my ($year, $month) = @$self{qw(year month)};

  my (@shade, @dates);

  # @shade indicates which days of week to shade
  foreach (@_) { $shade[$_ % 7] = 1 }

  my $dow = Day_of_Week($year, $month, 1) % 7;

  for my $date (1 .. Days_in_Month($year, $month)) {
    push @dates, $date if $shade[$dow];
    $dow = ($dow + 1) % 7;
  }

  $self->shade(@dates) if @dates;
} # end shade_days_of_week

#---------------------------------------------------------------------
sub print_calendar
{
  my ($self, $grid, %p) = @_;

  my $ps = $self->{psFile};

  $ps->add_to_page( <<"END_TITLE" );
$p{titleFont}$p{midpoint} $p{titleY} $S{$p{title}} showcenter
$p{labelFont}
END_TITLE

  my ($dayHeight, $dayWidth, $dateStartX)
      = @p{qw(dayHeight dayWidth dateStartX)};

  $dateStartX -= $dayWidth;

  my $x = $p{leftEdge} + $p{midday};
  foreach (@{ $p{dayNames} }) {
    $ps->add_to_page("$x $p{labelY} $S{$_} showcenter\n");
    $x += $dayWidth;
  }

  $ps->add_to_page($p{dateFont}) if $p{dateFont};

  my $showdate = $p{dateShow} || 'showright';
  my $y = $p{dayTop} - $p{dateSize} - $p{dateTopMar};

  foreach my $row (@$grid) {
    $x = $dateStartX;

    foreach my $day (@$row) {
      $x += $dayWidth;
      next unless $day;

      if (ref $day) {
        next unless $day->[0] eq 'split';
        $ps->add_to_page("$x $y $S{$day->[1]} $showdate\n" .
                         "$x $E{$y - $dayHeight/2} $S{$day->[2]} $showdate\n");
      } else {
        $ps->add_to_page("$x $y $S{$day} $showdate\n");
      }
    } # end foreach $day

    $y -= $dayHeight;
  } # end foreach $row

} # end print_calendar

#---------------------------------------------------------------------
sub print_mini_calendar
{
  my ($self, $year, $month, $x, $y, $width, $height) = @_;

  my $grid = $self->compute_grid($year, $month);

  my $cols = @{ $grid->[0] };

  my $linespacing = $self->{miniSize};
  my $sideMar = 6; # FIXME
  my $dayWidth = int(($width - 2 * $sideMar) * 4 / $cols) / 4.0;

  my $font = $self->{miniFont};
  $font =~ s/-iso$//;
  $font = Font::AFM->new($font);

  $self->print_calendar($grid,
    titleFont  => "MiniFont setfont\n",
    labelFont  => '',
    midpoint   => $x + $width/2,
    midday     => $font->stringwidth('22', $linespacing) / 2,
    titleY     => $y + $height - $linespacing,
    title      => Month_to_Text($month),
    dayHeight  => $linespacing,
    dayWidth   => $dayWidth,
    dateStartX => $x + $sideMar,# + $dayWidth,
    dateShow   => 'showleft',
    leftEdge   => $x + $sideMar,
    dayNames   => [ map { substr($_,0,1) } @{$self->{dayNames}} ],
    labelY     => $y + $height - 2 * $linespacing,
    dayTop     => $y + $height - 2 * $linespacing,
    dateSize   => $linespacing,
    dateTopMar => 0,
  );

} # end print_mini_calendar

#---------------------------------------------------------------------
sub print_events
{
  my ($self, $events, $x, $y, $width, $height, $special) = @_;

  my $ps = $self->{psFile};

  # Handle background:
  unshift @{$events->[evPS]}, $events->[evBackground]
      if $events->[evBackground];

  # Handle PostScript events:
  if ($events->[evPS]) {
    $ps->add_to_page("gsave\n$x $y translate\n");

    $ps->add_to_page("1 dict begin\n/DayHeight $height def\n")
        if $special;

    $ps->add_to_page(join "\n", @{ $events->[evPS] }, '');

    $ps->add_to_page("end\n") if $special;
    $ps->add_to_page("grestore\n");
  } # end if we have PostScript events

  # Handle text events:
  if ($events->[evTxt]) {
    my ($eventSize, $eventTopMar, $eventLeftMar, $eventRightMar) =
        @$self{qw(eventSize eventTopMar eventLeftMar eventRightMar)};
    my $startY = ($height - $eventSize - $eventTopMar
                  - ($events->[evTopMargin] || 0));

    my $text = join("\n", map { psstring($_) } @{ $events->[evTxt] });
    $ps->add_to_page(<<"END_EVENTS");
$E{$x + $eventLeftMar} $E{$y + $startY} [$text] Events
END_EVENTS
  } # end if we have text events
} # end print_events

#---------------------------------------------------------------------
sub generate
{
  my $self = $_[0];

  my ($ps, $days, $events, $year, $month, $topMar, $botMar, $sideMar, $mini,
      $titleSize, $dayLabelSize, $labelSkip)
      = @$self{qw(psFile days events year month topMar botMar sideMar mini
                  titleSize labelSize labelSkip)};

  my ($width, $height, $landscape) =
      ($ps->get_width, $ps->get_height, $ps->get_landscape);

  ($width, $height) = ($height, $width) if $landscape;

  my $dayWidth = int(($width - 2 * $sideMar) / @$days);
  my $midday   = $dayWidth / 2;
  my $gridWidth = $dayWidth * @$days;
  my $leftEdge = $sideMar;
  my $gridRight = $leftEdge + $gridWidth;

  my $midpoint = $width / 2;

  my $titleY = $height - $titleSize - $topMar;

  my $labelY   = $titleY - $dayLabelSize - $self->{titleSkip};

  my $dayTop = $labelY - $labelSkip;

  my $grid = $self->compute_grid($year, $month, $self->{condense});

  if ($mini) {
    my (@prev, @next);
    push @$grid, [ (undef) x @$days ] if @$grid == 4;

    if ($grid->[-1][-1] or
        ($mini eq 'before' and not $grid->[0][1]) or
        ($mini eq 'after'  and $grid->[-1][-2])) {
      @prev = (0,0);  @next = (0,1); # Both calendars at beginning
    } elsif ($grid->[0][0] or
             ($mini eq 'after' and not $grid->[-1][-2]) or
             ($mini eq 'before' and $grid->[0][1])) {
      @prev = (-1,-2);  @next = (-1,-1); # Both calendars at end
    } else {
      @prev = (0,0);  @next = (-1,-1); # Split between beginning & end
    }

    $grid->[$prev[0]][$prev[1]] = [calendar => Add_Delta_M($year, $month, -1)];
    $grid->[$next[0]][$next[1]] = [calendar => Add_Delta_M($year, $month,  1)];
  } # end if mini calendars

  my $dayHeight = int(($dayTop - $botMar) / @$grid);
  if ($dayHeight > ($self->{dayHeight} || $dayHeight)) {
    $dayHeight = $self->{dayHeight};
  }

  my $gridBottom = $dayTop - $dayHeight * @$grid;
  my $gridHeight = $dayTop - $gridBottom + $dayLabelSize + $labelSkip;
  my $gridTop    = $gridBottom + $gridHeight;

  $ps->add_to_page(<<"END_PAGE_INIT");
0 setlinecap
0 setlinejoin
2 pixel setlinewidth
END_PAGE_INIT

  unless ($ps->has_function('PostScript_Calendar'))
  { $ps->add_function('PostScript_Calendar', <<"END_FUNCTIONS") }
/DayHeight $dayHeight def
/DayWidth $dayWidth def
/TitleSize $titleSize def
/TitleFont /$self->{titleFont} findfont TitleSize scalefont def
/DateSize $self->{dateSize} def
/DateFont /$self->{dateFont} findfont DateSize scalefont def
/EventSize $self->{eventSize} def
/EventFont /$self->{eventFont} findfont EventSize scalefont def
/EventSpacing $E{$self->{eventSize} + $self->{eventSkip}} def
/MiniSize $self->{miniSize} def
/MiniFont /$self->{miniFont} findfont MiniSize scalefont def

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
} def

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
} def

%---------------------------------------------------------------------
% Shade a day with the default background:

/ShadeDay
{
  0.85 setgray
  FillDay
  0 setgray
} bind def
END_FUNCTIONS

  if ($self->{phases}) {
    my ($phase, @dates) = $self->calc_moon_phases($year, $month);
    my $margin = $self->{moonMargin} + $self->{dateSize};
    while (@dates) {
      if ($margin > ($events->[$dates[0]][evTopMargin] || 0)) {
        $events->[$dates[0]][evTopMargin] = $margin;
      }
      push @{$events->[shift @dates][evPS]}, "/$phaseName[$phase] ShowPhase";
      $phase = ($phase + 1) % 4;
    } # end while @dates

    unless ($ps->has_function('PostScript_Calendar_Moon'))
    { $ps->add_function('PostScript_Calendar_Moon', <<"END_MOON_FUNCTIONS") }
/MoonMargin $self->{moonMargin} def

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
} def

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
} def

/LastQuarter
{
  FullMoon
  newpath
  MoonMargin DateSize 2 div add
  DayHeight MoonMargin sub DateSize 2 div sub
  DateSize 2 div
  270 90 arc
  closepath fill
} def
END_MOON_FUNCTIONS
  } # end if showing phases of the moon

  my $splitHeight = $dayHeight/2;

  my $y = $dayTop;
  foreach my $row (@$grid) {
    $y -= $dayHeight;
    my $x = $leftEdge - $dayWidth;

    foreach my $day (@$row) {
      $x += $dayWidth;
      next unless $day;

      if (ref $day) {
        if ($day->[0] eq 'split') {
          my $lineY = $y + $splitHeight;
          $self->print_events($events->[$day->[1]], $x, $lineY,
                              $dayWidth, $splitHeight, 1)
              if $events->[$day->[1]];
          $self->print_events($events->[$day->[2]], $x, $y,
                              $dayWidth, $splitHeight, 1)
              if $events->[$day->[2]];

          $ps->add_to_page(<<"END_SPLIT_LINE");
$dayWidth $x $lineY hline
END_SPLIT_LINE
        } elsif ($day->[0] eq 'calendar') {
          $self->print_mini_calendar(@$day[1,2], $x, $y, $dayWidth, $dayHeight);
        }
      } else {
        $self->print_events($events->[$day], $x, $y, $dayWidth, $dayHeight)
            if $events->[$day];
      }
    } # end foreach $day
  } # end foreach $row

  $self->print_calendar($grid,
    titleFont  => "TitleFont setfont\n",
    labelFont  => '',
    dateFont   => "DateFont setfont\n",
    midpoint   => $midpoint,
    midday     => $midday,
    titleY     => $titleY,
    title      => $self->{title},
    dayHeight  => $dayHeight,
    dayWidth   => $dayWidth,
    dateStartX => $leftEdge + $dayWidth - $self->{dateRightMar},
    leftEdge   => $leftEdge,
    dayNames   => $self->{dayNames},
    labelY     => $labelY,
    dayTop     => $dayTop,
    dateSize   => $self->{dateSize},
    dateTopMar => $self->{dateTopMar},
  );

  $ps->add_to_page(<<"END_HOR_LINES");
$E{$gridBottom + $dayHeight} $dayHeight $dayTop\ {
  $gridWidth $leftEdge 3 -1 roll hline
} for
END_HOR_LINES

  $ps->add_to_page(<<"END_VERT_LINES");
$E{$leftEdge + $dayWidth} $dayWidth $E{$gridRight - $midday}\ {
  $gridHeight exch $gridBottom vline
} for
END_VERT_LINES

  if ($self->{border}) {
    $ps->add_to_page(<<"END_BORDER");
newpath
$leftEdge $gridTop moveto
$gridWidth 0 rlineto
0 -$gridHeight rlineto
-$gridWidth 0 rlineto
closepath stroke
END_BORDER
  } else {
    $ps->add_to_page("$gridWidth $leftEdge $gridTop hline\n");
  }

  $self->{generated} = 1;
} # end generate

#---------------------------------------------------------------------
sub output
{
  my $self = shift @_;

  $self->generate unless $self->{generated};

  $self->{psFile}->output(@_);
} # end output

#---------------------------------------------------------------------
sub ps_file { $_[0]->{ps_file} }

#=====================================================================
# Package Return Value:

1;

__END__

=head1 NAME

PostScript::Calendar - [One line description of module's purpose here]

=head1 VERSION

This document describes PostScript::Calendar version 0.01


=head1 SYNOPSIS

    use PostScript::Calendar;

=for author to fill in:
    Brief code example(s) here showing commonest usage(s).
    This section will be as far as many users bother reading
    so make it as educational and exeplary as possible.


=head1 DESCRIPTION

=for author to fill in:
    Write a full description of the module and its features here.
    Use subsections (=head2, =head3) as appropriate.


=head1 INTERFACE

=for author to fill in:
    Write a separate section listing the public components of the modules
    interface. These normally consist of either subroutines that may be
    exported, or methods that may be called on objects belonging to the
    classes provided by the module.


=head1 DIAGNOSTICS

=for author to fill in:
    List every single error and warning message that the module can
    generate (even the ones that will "never happen"), with a full
    explanation of each problem, one or more likely causes, and any
    suggested remedies.

=over

=item C<< Error message here, perhaps with %s placeholders >>

[Description of error here]

=item C<< Another error message here >>

[Description of error here]

[Et cetera, et cetera]

=back


=head1 CONFIGURATION AND ENVIRONMENT

=for author to fill in:
    A full explanation of any configuration system(s) used by the
    module, including the names and locations of any configuration
    files, and the meaning of any environment variables or properties
    that can be set. These descriptions must also include details of any
    configuration language used.

PostScript::Calendar requires no configuration files or environment variables.


=head1 DEPENDENCIES

=for author to fill in:
    A list of all the other modules that this module relies upon,
    including any restrictions on versions, and an indication whether
    the module is part of the standard Perl distribution, part of the
    module's distribution, or must be installed separately. ]

None.


=head1 INCOMPATIBILITIES

=for author to fill in:
    A list of any modules that this module cannot be used in conjunction
    with. This may be due to name conflicts in the interface, or
    competition for system or program resources, or due to internal
    limitations of Perl (for example, many modules that use source code
    filters are mutually incompatible).

None reported.


=head1 BUGS AND LIMITATIONS

=for author to fill in:
    A list of known problems with the module, together with some
    indication Whether they are likely to be fixed in an upcoming
    release. Also a list of restrictions on the features the module
    does provide: data types that cannot be handled, performance issues
    and the circumstances in which they may arise, practical
    limitations on the size of data sets, special cases that are not
    (yet) handled, etc.

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-postscript-calendar@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Christopher J. Madsen  C<< <cjm@pobox.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright 2006, Christopher J. Madsen C<< <cjm@pobox.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
