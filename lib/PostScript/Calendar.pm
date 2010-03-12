#---------------------------------------------------------------------
package PostScript::Calendar;
#
# Copyright 2010 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: Sat Nov 25 14:32:55 2006
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: Generate a monthly calendar in PostScript
#---------------------------------------------------------------------

use 5.008;
use warnings;
use strict;
use Carp;
use Date::Calc qw(Add_Delta_YM Day_of_Week Day_of_Week_to_Text
                  Days_in_Month Localtime Mktime Month_to_Text);
use Font::AFM;
use PostScript::File qw(pstr);

#=====================================================================
# Package Global Variables:

our $VERSION = '0.05';

our @phaseName = qw(NewMoon FirstQuarter FullMoon LastQuarter);

#---------------------------------------------------------------------
# Tied hashes for interpolating function calls into strings:

{ package PostScript::Calendar::Interpolation;

  sub TIEHASH { bless $_[1], $_[0] }
  sub FETCH   { $_[0]->($_[1]) }
} # end PostScript::Calendar::Interpolation

our (%E, %S);
tie %E, 'PostScript::Calendar::Interpolation', sub { $_[0] }; # eval
tie %S, 'PostScript::Calendar::Interpolation', \&pstr; # quoted string

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
# Round to an integer, but preserve undef:

sub round
{
  defined $_[0] ? sprintf('%d', $_[0]) : $_[0];
} # end round

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

# This is one time subroutine prototypes are useful:
## no critic (ProhibitSubroutinePrototypes)

sub evTxt        () { 0 }
sub evPS         () { 1 }
sub evBackground () { 2 }
sub evTopMargin  () { 3 }

## use critic

#=====================================================================
# Package PostScript::Calendar:

sub new
{
  my ($class, $year, $month, %p) = @_;

  my $self = bless {
    events    => [],
    psFile    => $p{ps_file},
    condense  => $p{condense},
    border    => firstdef($p{border}, 1),
    dayHeight => round($p{day_height}),
    mini      => $p{mini_calendars},
    phases    => $p{phases},
    title     => firstdef($p{title},
                          sprintf '%s %d', Month_to_Text($month), $year),
    days      => ($p{days} || [ 0 .. 6 ]), # Sun .. Sat
    year      => $year,
    month     => $month,
    sideMar   => round(firstdef($p{side_margins},  $p{margin}, 24)),
    topMar    => round(firstdef($p{top_margin},    $p{margin}, 36)),
    botMar    => round(firstdef($p{bottom_margin}, $p{margin}, 24)),
    titleFont => $p{title_font} || 'Helvetica-iso',
    titleSize => $p{title_size} || 14,
    titleSkip => round(firstdef($p{title_skip}, 5)),
    labelFont => $p{label_font} || $p{title_font} || 'Helvetica-iso',
    labelSize => $p{label_size} || $p{title_size} || 14,
    labelSkip => round(firstdef($p{label_skip}, $p{title_skip}, 5)),
    dateFont  => $p{date_font} || 'Helvetica-Oblique-iso',
    dateSize  => $p{date_size} || $p{title_size} || 14,
    eventFont => $p{event_font} || 'Helvetica-iso',
    eventSize => $p{event_size} || 8,
    eventSkip => firstdef($p{event_skip}, 2),
    miniFont  => $p{mini_font} || 'Helvetica-iso',
    miniSize  => $p{mini_size} || 6,
    miniSkip  => firstdef($p{mini_skip}, 3),
    dateRightMar => firstdef($p{date_right_margin}, 4),
    dateTopMar   => firstdef($p{date_top_margin},   2),
    eventTopMar   => firstdef($p{event_top_margin},   $p{event_margin}, 2),
    eventLeftMar  => firstdef($p{event_left_margin},  $p{event_margin}, 3),
    eventRightMar => firstdef($p{event_right_margin}, $p{event_margin}, 2),
    miniSideMar   => firstdef($p{mini_side_margins}, $p{mini_margin}, 4),
    miniTopMar    => firstdef($p{mini_top_margin},   $p{mini_margin}, 4),
    moonMargin    => firstdef($p{moon_margin}, 6),
  }, $class;

  my $days     = $self->{days};
  my $firstDay = $days->[0];
  $self->{dayOffsets} = [ map { $_ - $firstDay } @$days ];

  $self->{dayNames} =
      ($p{day_names} or
       [ map { Day_of_Week_to_Text($_ % 7 || 7) } @$days ]);

  if (not length $self->{title}) {
    $self->{titleSize} = 0;
    $self->{titleSkip} = 0;
  } # end if title is suppressed

  unless ($self->{psFile}) {
    $self->{psFile} = PostScript::File->new(
      paper       => ($p{paper} || 'Letter'),
      top         => $self->{topMar},
      left        => $self->{sideMar},
      right       => $self->{sideMar},
      title       => pstr($self->{title}),
      reencode    => 'ISOLatin1Encoding',
      font_suffix => '-iso',
      landscape   => $p{landscape},
    );
  }

  $self->shade_days_of_week(@{ $p{shade_days_of_week} })
      if $p{shade_days_of_week};

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
sub get_metrics
{
  my ($self, $font) = @_;
  $font =~ s/-iso$//;

  my $metrics = $self->{fontCache}{$font};

  return $metrics if $metrics;

  $self->{fontCache}{$font} = Font::AFM->new($font);
} # end get_metrics

#---------------------------------------------------------------------
sub add_event
{
  my ($self, $date, $message) = @_;

  push @{$self->{events}[$date][evTxt]}, split(/[ \t]*\n/, $message);
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

  $ps->add_to_page( <<"END_TITLE" ) if length($p{title});
$p{titleFont}$p{midpoint} $p{titleY} $S{$p{title}} showcenter
END_TITLE

  $ps->add_to_page("$p{labelFont}\n");

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

  my $yTop = $y + $height - $self->{miniTopMar};
  my $grid = $self->compute_grid($year, $month);
  my $cols = @{ $grid->[0] };

  my $fontsize    = $self->{miniSize};
  my $linespacing = $fontsize + $self->{miniSkip};
  my $sideMar     = $self->{miniSideMar};

  my $font = $self->get_metrics($self->{miniFont});
  my $numWidth = $font->stringwidth('22', $fontsize);

  my $colSpacing = (($cols > 1)
                    ? ($width - 2 * $sideMar - $cols * $numWidth) / ($cols - 1)
                    : 0);

  my $dayWidth = int(($numWidth + $colSpacing) * 8) / 8.0; # Round to 1/8
  my $midday   = int($numWidth * 4) / 8.0; # Divide by 2 and round to 1/8

  $self->print_calendar($grid,
    titleFont  => "MiniFont setfont\n",
    labelFont  => '',
    midpoint   => $x + $width/2,
    midday     => $midday,
    titleY     => $yTop - $fontsize,
    title      => Month_to_Text($month),
    dayHeight  => $linespacing,
    dayWidth   => $dayWidth,
    dateStartX => $x + $sideMar + $midday,
    dateShow   => 'showcenter',
    leftEdge   => $x + $sideMar,
    dayNames   => [ map { substr($_,0,1) } @{$self->{dayNames}} ],
    labelY     => $yTop - $fontsize - $linespacing,
    dayTop     => $yTop - 2 * $linespacing,
    dateSize   => $fontsize,
    dateTopMar => 0,
  );

} # end print_mini_calendar

#---------------------------------------------------------------------
sub print_events
{
  my ($self, $eventArray, $date, $x, $y, $width, $height, $special) = @_;

  my $events = $eventArray->[$date];
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
    my $useY = $height - $eventTopMar - ($events->[evTopMargin] || 0);

    my $text = $self->wrap_events($useY, $width, $height, $events->[evTxt],
                                  $date);
    $ps->add_to_page(<<"END_EVENTS");
$E{$x + $eventLeftMar} $E{$y + $useY - $eventSize} [$text] Events
END_EVENTS
  } # end if we have text events
} # end print_events

#---------------------------------------------------------------------
sub wrap_events
{
  my ($self, $y, $width, $height, $events, $date) = @_;

  my $metrics      = $self->get_metrics($self->{eventFont});
  my $eventSize    = $self->{eventSize};
  my $eventSpacing = $eventSize + $self->{eventSkip};

  my $dateSize   = $self->{dateSize};
  my $dateBottom = $height - $dateSize - $self->{dateTopMar};

  my $fullWidth = ($width -= $self->{eventLeftMar} + $self->{eventRightMar});

  if ($y > $dateBottom) {
    my $dateMetrics = $self->get_metrics($self->{dateFont});

    $width -= ($dateMetrics->stringwidth($date, $dateSize) +
               $self->{dateRightMar});
  }

  my $next;

  for (my $i = 0; $i <= $#$events; ++$i, $y -= $eventSpacing) {
    $width = $fullWidth if $y < $dateBottom;

    if ($y < $eventSize) {
      carp sprintf("WARNING: Event text for %s-%02d-%02d doesn't fit",
                   $self->{year}, $self->{month}, $date);
      splice @$events, $i, scalar @$events;
      last;
    } # end if we ran out of space

    for ($events->[$i]) {
      s/\s+$//;                 # Remove trailing space, if any

      $next = '';
      while (($metrics->stringwidth($_, $eventSize) > $width) and
             (s/-([^- \t]+-*)$/-/ or
              s/([ \t]+[^- \t]*-*)$// or
              s/(.)$//)) {
        $next = $1 . $next;
      } # end while string too wide

      if (length $next) {
        $next =~ s/^\s+//;
        splice @$events, $i+1,0, $next;
      } # end if string was too wide
    } # end for this event string
  } # end for each event

  join("\n", map { pstr($_) } @$events);
} # end wrap_events

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

  my $dayWidth = round(($width - 2 * $sideMar) / @$days);
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

  my $dayHeight = round(($dayTop - $botMar) / @$grid);
  if ($dayHeight > ($self->{dayHeight} || $dayHeight)) {
    $dayHeight = $self->{dayHeight};
  }

  my $gridBottom = $dayTop - $dayHeight * @$grid;
  my $gridHeight = $dayTop - $gridBottom + $dayLabelSize + $labelSkip;
  my $gridTop    = $gridBottom + $gridHeight;

  $ps->add_comment(sprintf 'Creator: %s %s', ref($self), $self->VERSION);

  $ps->add_to_page(<<"END_PAGE_INIT");
0 setlinecap
0 setlinejoin
3 pixel setlinewidth

/DayHeight $dayHeight def
/DayWidth $dayWidth def
/TitleSize $titleSize def
/TitleFont /$self->{titleFont} findfont TitleSize scalefont def
/LabelSize $dayLabelSize def
/LabelFont /$self->{labelFont} findfont LabelSize scalefont def
/DateSize $self->{dateSize} def
/DateFont /$self->{dateFont} findfont DateSize scalefont def
/EventSize $self->{eventSize} def
/EventFont /$self->{eventFont} findfont EventSize scalefont def
/EventSpacing $E{$self->{eventSize} + $self->{eventSkip}} def
/MiniSize $self->{miniSize} def
/MiniFont /$self->{miniFont} findfont MiniSize scalefont def
END_PAGE_INIT

  unless ($ps->has_function('PostScript_Calendar'))
  { $ps->add_function('PostScript_Calendar', <<'END_FUNCTIONS') }
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

    $ps->add_to_page("/MoonMargin $self->{moonMargin} def\n");

    unless ($ps->has_function('PostScript_Calendar_Moon'))
    { $ps->add_function('PostScript_Calendar_Moon', <<'END_MOON_FUNCTIONS') }
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
          $self->print_events($events, $day->[1], $x, $lineY,
                              $dayWidth, $splitHeight, 1)
              if $events->[$day->[1]];
          $self->print_events($events, $day->[2], $x, $y,
                              $dayWidth, $splitHeight, 1)
              if $events->[$day->[2]];

          $ps->add_to_page(<<"END_SPLIT_LINE");
$dayWidth $x $lineY hline
END_SPLIT_LINE
        } elsif ($day->[0] eq 'calendar') {
          $self->print_mini_calendar(@$day[1,2], $x, $y, $dayWidth, $dayHeight);
        }
      } else {
        $self->print_events($events, $day, $x, $y, $dayWidth, $dayHeight)
            if $events->[$day];
      }
    } # end foreach $day
  } # end foreach $row

  $self->print_calendar($grid,
    titleFont  => "TitleFont setfont\n",
    labelFont  => "LabelFont setfont\n",
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

=head1 SYNOPSIS

  use PostScript::Calendar;

  my $cal = PostScript::Calendar->new($year, $month, phases => 1,
                                      mini_calendars => 'before');
  $cal->output('filename');


=head1 DESCRIPTION

PostScript::Calendar generates printable calendars using PostScript.

PostScript::Calendar uses Date::Calc's C<*_to_Text> functions, so you
can change the language used by calling Date::Calc's C<Language>
function before creating your calendar.

Years must be fully specified (e.g., use 1990, not 90).  Months range
from 1 to 12.  Days of the week can be specified as 0 to 7 (where
Sunday is either 0 or 7, Monday is 1, etc.).

All dimensions are specified in PostScript points (72 per inch).

=head1 INTERFACE

=head2 C<< $cal = PostScript::Calendar->new($year, $month, [key => value, ...]) >>

This constructs a new PostScript::Calendar object for C<$year> and C<$month>.

There are a large number of parameters you can pass to customize how
the calendar is displayed.  They are all passed as S<< C<< name => value >> >>
pairs.

=over

=item C<border>

If false, omit the border around the calendar grid (only internal grid
lines are drawn).  The default is true.

=item C<condense>

If true, reduce calendars that would span 6 rows down to 5 rows by
combining either the first or last day with its neighbor.  The default
is false.

=item C<day_height>

The maximum height of a date row.  This is useful to prevent
portrait-mode calendars from taking up the entire page (which just
doesn't look right).  The default is 0, which means there is no
maximum value.  I recommend 96 for a portrait-mode calendar on US
letter size paper.

=item C<mini_calendars>

This causes small calendars for the previous and next months to be
printed.  The value should be C<"before"> to put them before the first
of the month, C<"after"> to put them after the last day of the month, or
C<"split"> to put the previous month before and the next month after.
The default is a false value (which means no mini calendars).

=item C<phases>

If true, the phase of the moon icons are printed (requires
Astro::MoonPhase 0.60).  The default is false.

=item C<title>

The title to be printed at the top of the calendar.  The default is
"Month YEAR" (where Month comes from Month_to_Text, and YEAR is
numeric.)  Setting this to the empty string automatically sets
C<title_size> and C<title_skip> to 0 (completely suppressing the title).

=item C<days>

An arrayref specifying the days of the week to be included in the
calendar.  The first day must be in the range 0 to 6 (where Sunday is
0, Monday is 1, etc.).  Subsequent days must be in ascending order, up
to the initial day + 6.The default is S<C<[ 0 .. 6 ]>> (meaning Sunday
thru Saturday).  Other popular values are S<C<[ 1 .. 7 ]>> for Monday
thru Sunday or S<C<[ 1 .. 5 ]>> for Monday thru Friday (no weekends).

You may skip over days if you don't want them included.  For example,
S<C<[ 3, 5, 8 ]>> would display Wednesday, Friday, and Monday (with weeks
starting on Wednesday).

=item C<day_names>

Arrayref of the column labels.  Defaults to passing the (normalized)
values from C<days> thru Date::Calc's C<Day_of_Week_to_Text>, which is
probably what you want.

=item C<title_font>

The font to use for the C<title>.  Defaults to Helvetica-iso.

=item C<title_size>

The size of the C<title_font> to use.  Defaults to 14.

=item C<title_skip>

Extra space (in points) to leave below the C<title>.  Defaults to 5.

=item C<label_font>

The font to use for the days of the week.  Defaults to C<title_font>.

=item C<label_size>

The size of the C<label_font> to use.  Defaults to C<title_size>.

=item C<label_skip>

Extra space (in points) to leave below the weekday labels.  Defaults
to C<title_skip>.

=item C<date_font>

The font to use for the dates of the month.  Defaults to Helvetica-Oblique-iso.

=item C<date_size>

The size of the C<date_font> to use.  Defaults to C<title_size>.

=item C<event_font>

The font to use for text events (added by C<add_event>).  Defaults to
Helvetica-iso.

=item C<event_size>

The size of the C<event_font> to use.  Defaults to 8.

=item C<event_skip>

Extra space (in points) to leave between lines of event text.  Defaults
to 2.

=item C<mini_font>

The font to use for mini calendars.  Defaults to Helvetica-iso.

=item C<mini_size>

The size of the C<mini_font> to use.  Defaults to 6.

=item C<mini_skip>

Extra space (in points) to leave between the lines of mini calendars.
Defaults to 3.

=item C<date_right_margin>

Space (in points) to leave between the date and the gridline.  Defaults to 4.

=item C<date_top_margin>

Space (in points) to leave between the date and the gridline.  Defaults to 2.

=item C<event_margin>

This is used as the default value for C<event_top_margin>,
C<event_left_margin>, and C<event_right_margin>.

=item C<event_top_margin>

The space (in points) to leave above event text.  Defaults to
C<event_margin>, or 2 if C<event_margin> is not specified.

=item C<event_left_margin>

The space (in points) to leave to the left of event text.  Defaults
to C<event_margin>, or 3 if C<event_margin> is not specified.

=item C<event_right_margin>

The space (in points) to leave to the right of event text.  Defaults to
C<event_margin>, or 2 if C<event_margin> is not specified.

=item C<mini_margin>

This is used as the default value for C<mini_top_margin> and
C<mini_side_margins>.  Defaults to 4.

=item C<mini_top_margin>

The space (in points) to leave above mini calendars.  Defaults to
C<mini_margin>.

=item C<mini_side_margins>

The space (in points) to leave on each side of mini calendars.
Defaults to C<mini_margin>.

=item C<moon_margin>

Space to leave above and to the left of the moon icon.  Defaults to 6.

=item C<shade_days_of_week>

An arrayref of days of the week to be passed to the
C<shade_days_of_week> method.  (I found it convenient to be able to pass
this to the constructor instead of making a separate method call.)

=item C<margin>

This is used as the default value for C<top_margin>, C<side_margins>,
and C<bottom_margin>.

=item C<side_margins>

The space (in points) to leave on each side of the calendar.  Defaults
to C<margin>, or 24 if C<margin> is not specified.

=item C<top_margin>

The space (in points) to leave above the calendar.  Defaults to
C<margin>, or 36 if C<margin> is not specified.

=item C<bottom_margin>

The space (in points) to leave below the calendar.  Defaults to
C<margin>, or 24 if C<margin> is not specified.

=item C<paper>

The paper size to pass to PostScript::File.  Defaults to C<"Letter">.
Not used if you supply C<ps_file>.

=item C<landscape>

If true, print calendar in landscape mode.  Defaults to false.
Not used if you supply C<ps_file>.

=item C<ps_file>

Allows you to pass in a PostScript::File (or compatible) object for
the calendar to use.  By default, a new PostScript::File object is
created.

=back

=head2 C<< $cal->add_event($date, $message) >>

This prints the text C<$message> on C<$date>, where C<$date> is the
day of the month.  You may call this multiple times for the same date.
Messages will be printed in the order they were added.  C<$message>
may contain newlines to force line breaks.

=head2 C<< $cal->shade($date, ...) >>

This colors the background of the specified date(s) a light gray,
where C<$date> is the day of the month.  Any number of dates can be
given.

=head2 C<< $cal->shade_days_of_week($day, ...) >>

This calls C<shade> for all dates that fall on the specified day(s) of
the week.  Each C<$day> should be 0-7 (where Sunday is either 0 or 7).

=head2 C<< $cal->generate >>

This actually generates the calendar, placing it in the
PostScript::File object.  You shouldn't need to call this, because
C<output> calls it automatically.

=head2 C<< $cal->output($filename) >>

This passes its parameters to C<PostScript::File::output> (after
calling C<generate> if necessary).  Normally, you just pass the
filename to write.  Note that PostScript::File will append ".ps" to
the output filename.

=head2 C<< $cal->ps_file >>

This returns the PostScript::File object that C<$cal> is using.  Only
needed for advanced techniques.

=head1 DIAGNOSTICS

=over

=item C<< WARNING: Event text for YYYY-MM-DD doesn't fit >>

You supplied more event text for the specified date than would fit in
the box.  You'll have to use a smaller font, smaller margins, or less
text.

=back


=head1 CONFIGURATION AND ENVIRONMENT

PostScript::Calendar requires no configuration files or environment variables.

However, it uses L<Font::AFM>, and unfortunately that's difficult to
configure properly.  I wound up creating symlinks in
C</usr/local/lib/afm/> (which is one of the default paths that
Font::AFM searches if you don't have a C<METRICS> environment
variable):

 Helvetica.afm         -> /usr/share/fonts/afms/adobe/phvr8a.afm
 Helvetica-Oblique.afm -> /usr/share/fonts/afms/adobe/phvro8a.afm

Paths on your system may vary.  I suggest searching for C<.afm> files,
and then grepping them for "FontName Helvetica".  Helvetica and
Helvetica-Oblique are the two fonts that PostScript::Calendar uses by
default, and Font::AFM expects to find files named C<Helvetica.afm>
and C<Helvetica-Oblique.afm>.

=head1 DEPENDENCIES

L<Date::Calc> (5.0 or later), L<Font::AFM>, and L<PostScript::File>.

If you want to display phases of the moon, you'll need
L<Astro::MoonPhase> 0.60 or later.


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=for Pod::Coverage::TrustPod
^Add_Delta_M
^calc_moon_phases
^compute_grid
^ev[A-Z]
^firstdef
^get_metrics
^print_calendar
^print_events
^print_mini_calendar
^round
^wrap_events
