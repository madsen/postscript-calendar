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
                  Days_in_Month Month_to_Text);
use Font::AFM;

#=====================================================================
# Package Global Variables:

our $VERSION = '0.01';

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
# Add delta months:
#
# ($year, $month) = Add_Delta_M($year, $month, $delta_months);

sub Add_Delta_M
{
  (Add_Delta_YM($_[0], $_[1], 1, 0, $_[2]))[0,1];
}

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
    title     => ($p{title} || sprintf '%s %d', Month_to_Text($month), $year),
    days      => ($p{days} || [ 0 .. 6 ]), # Sun .. Sat
    year      => $year,
    month     => $month,
    sideMar   => (defined $p{side_margins} ? $p{side_margins} : 24),
    topMar    => (defined $p{top_margin} ? $p{top_margin} : 36),
    botMar    => (defined $p{bottom_margin} ? $p{bottom_margin} : 24),
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
sub add_calendar
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

} # end add_calendar

sub add_mini_calendar
{
  my ($self, $year, $month, $x, $y, $width, $height) = @_;

  my $grid = $self->compute_grid($year, $month);

  my $cols = @{ $grid->[0] };

  my $linespacing = 7;
  my $sideMar = 6;
  my $dayWidth = int(($width - 2 * $sideMar) * 4 / $cols) / 4.0;

  my $font = Font::AFM->new('Helvetica'); # FIXME

  $self->add_calendar($grid,
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

} # end add_mini_calendar

#---------------------------------------------------------------------
sub generate
{
  my $self = $_[0];

  my ($ps, $days, $year, $month, $topMar, $botMar, $sideMar, $mini)
      = @$self{qw(psFile days year month topMar botMar sideMar mini)};

  my ($width, $height, $landscape) =
      ($ps->get_width, $ps->get_height, $ps->get_landscape);

  ($width, $height) = ($height, $width) if $landscape;

  my $dayWidth = int(($width - 2 * $sideMar) / @$days);
  my $midday   = $dayWidth / 2;
  my $gridWidth = $dayWidth * @$days;
  my $leftEdge = $sideMar;
  my $gridRight = $leftEdge + $gridWidth;

  my $midpoint = $width / 2;
  my $titleSize = 14;
  my $dayLabelSize = 14;
  my $dateSize = 14;
  my $dateRightMar = 4;
  my $dateTopMar = 2;

  my $titleY = $height - $titleSize - $topMar;

  my $labelMar = 5;
  my $labelY   = $titleY - $dayLabelSize - $labelMar;

  my $dayTop = $labelY - $labelMar;

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
  my $gridHeight = $dayTop - $gridBottom + $dayLabelSize + $labelMar;
  my $gridTop    = $gridBottom + $gridHeight;

  unless ($ps->has_function('PostScript_Calendar'))
  { $ps->add_function('PostScript_Calendar', <<"END_FUNCTIONS") }
/DayHeight $dayHeight def
/DayWidth $dayWidth def
/TitleSize $titleSize def
/TitleFont /Helvetica-iso findfont TitleSize scalefont def
/DateSize $titleSize def
/DateFont /Helvetica-Oblique-iso findfont DateSize scalefont def
/MiniSize 7 def % FIXME
/MiniFont /Helvetica-iso findfont MiniSize scalefont def

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
END_FUNCTIONS

  my $y = $dayTop;
  foreach my $row (@$grid) {
    $y -= $dayHeight;
    my $x = $leftEdge - $dayWidth;

    foreach my $day (@$row) {
      $x += $dayWidth;
      next unless $day;

      if (ref $day) {
        if ($day->[0] eq 'split') {
          my $lineY = $y + $dayHeight/2;
          $ps->add_to_page(<<"END_SPLIT_LINE");
0 setlinecap
2 pixel setlinewidth
$dayWidth $x $lineY hline
END_SPLIT_LINE
        } elsif ($day->[0] eq 'calendar') {
          $self->add_mini_calendar(@$day[1,2], $x, $y, $dayWidth, $dayHeight);
        }
      } else {
      }
    } # end foreach $day
  } # end foreach $row

  $self->add_calendar($grid,
    titleFont  => "TitleFont setfont\n",
    labelFont  => '',
    dateFont   => "DateFont setfont\n",
    midpoint   => $midpoint,
    midday     => $midday,
    titleY     => $titleY,
    title      => $self->{title},
    dayHeight  => $dayHeight,
    dayWidth   => $dayWidth,
    dateStartX => $leftEdge + $dayWidth - $dateRightMar,
    leftEdge   => $leftEdge,
    dayNames   => $self->{dayNames},
    labelY     => $labelY,
    dayTop     => $dayTop,
    dateSize   => $dateSize,
    dateTopMar => $dateTopMar,
  );

  $ps->add_to_page(<<"END_HOR_LINES");
0 setlinecap
2 pixel setlinewidth
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
0 setlinejoin
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
