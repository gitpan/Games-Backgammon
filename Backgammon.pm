package Games::Backgammon;

use 5.006001;
use strict;
use warnings;

use List::Util qw/min max sum first/;
use Carp;

require Exporter;

our @ISA = qw(Exporter);

our $VERSION = '0.02';

sub new {
    my ($class, %arg) = @_;
    $class = ref($class) || $class;
    croak "Sorry, but I need a starting position" unless defined $arg{position};
    my $self = {
        whitepoints => undef,
        blackpoints => undef,
        atroll      => 'black',
    };
    bless $self => $class;
    $self->_init(%arg);
    return $self;
}

sub _init {
    my ($self, %arg) = @_;
    $self->set_position(%{$arg{position}});
}

sub set_position {
    my ($self, %pos) = @_;
    my %white  = %{$pos{whitepoints} || {}};
    my %black  = %{$pos{blackpoints} || {}};
    
    $white{off} ||= max(0, 15 - _checkers_in_play(%white));
    $black{off} ||= max(0, 15 - _checkers_in_play(%black));
    
    carp "White has > 15 checkers in play" if _checkers_in_play(%white) > 15;
    carp "Black has > 15 checkers in play" if _checkers_in_play(%black) > 15;
    
    if (my @unknown_points = grep !m/([1-9]|1\d|2[0-4]|bar|off)/,
                             keys %white, keys %black)
    { croak "Don't know what you mean for points with '@unknown_points'" }                            
    
    if (my @collisions = grep {$white{$_} && $black{25-$_}} (1 .. 24)) {
        croak "White checkers on @collisions collide with " .
              "black ones on the same points";
    }
    
    croak "Illegal position: Both players are on the bar " .
          "and are on the bar"
        if grep($_, (@white{1..6,'bar'}, @black{1..6,'bar'})) >= 2 * 6 + 2;
    
    $self->{whitepoints} = \%white;
    $self->{blackpoints} = \%black;
    
    my $atroll = exists $pos{atroll} ? lc($pos{atroll}) : 'black';
    croak "The player at roll can be black or white -- nothing else"
        unless($atroll =~ /^(black|white)$/);
    $self->{atroll} = $atroll;
}

sub _checkers_in_play {
    my %point = @_;
    sum map {$point{$_}} grep m/^([1-9]|1\d|2[0-4]|bar)$/i, keys %point
    or 0;
}

sub whitepoints {
    my ($self, $point) = @_;
    $point 
        ? ($self->{whitepoints}->{$point} || 0) 
        : _only_real_points( %{$self->{whitepoints}} );
}

sub blackpoints {
    my ($self, $point) = @_;
    $point 
        ? ($self->{blackpoints}->{$point} || 0) 
        : _only_real_points( %{$self->{blackpoints}} );
}

sub _only_real_points { my %p = @_; map {($_ => $p{$_})} grep {$p{$_}} keys %p }

sub atroll {
    my ($self) = @_;
    return $self->{atroll};
}


1;

__END__
=head1 NAME

Games::Backgammon - Perl extension for modelling backgammon games

=head1 SYNOPSIS

  use Games::Backgammon;
  
  my $game = Games::Backgammon->new(
    position => {
      whitepoints => {3 => 1, 4 => 1, 5 => 3, 6 => 3}, # ideal 40 pip position
      blackpoints => {4 => 3, 5 => 5, 6 => 7},         # ideal 79 pip position
      atroll      => 'black',
    }
  );
  
  print "Checkers off from white", $game->whitepoints('off');
  
  ## Not implemented yet
  
  $game->manual_roll('6-5');
  print "Now you can do these moves: ", join " ", $game->movelist;
  
  $game->move('6-off 5-off');
  
  print join "\n", 
    "Now black has a pip count of " . $game->blackpips,
    "With " . $game->blackpoints('off') . " checkers off the game";
    
  
=head1 DESCRIPTION

This module helps modelling backgammon games.
It is not basically intented to play backgammon for itself.
I just wrote it to analyze (long) racings in a convenient way.

=head2 FUNCTIONS

=over

=item my $game = Games::Backgammon->new(position => \%pos)

This creates a new backgammon game.
At the moment, it's necessary to define the starting position.
The reason is that I just have not yet programmed how to do the beginning roll.

Please look to the documentation of set_position for the definition of the
position hash. 

=item $game->set_position(%pos)

Resets the backgammon game to a specific position.
You can specify the position of the checkers and who is at the roll.
(Of course, in future versions, I'll also add the doubling cube to the position,
and the possibility of doubling before a rol).

Thus the position hash has the following outlook:

  position => {
     whitepoints => {$point1 => $nr_of_white_checkers_on_point1,
                     $point2 => $nr_of_white_checkers_on_point2,
                     ...
                     'bar'   => $nr_of_white_checkers_on_the_bar},

     blackpoints => {$point1 => $nr_of_black_checkers_on_point1,
                     $point2 => $nr_of_black_checkers_on_point2,
                     ...
                     'bar'   => $nr_of_black_checkers_on_the_bar},
     
     atroll      => 'white'     # or 'black'
  }
  
With the C<whitepoints> and <blackpoints> arguments, you can define where the
checkers of each side are. The point numbers are always regarded from the
player's view. So point x for white is point (25-x) for black. Please take care
that black's and white's checkers are not at the same point (what would result
in an error). It's also forbidden that both players have a closed board and
both players have checkers on the bar. Specifying more than 15 checkers for a
side is allowed, but it gives a warning. 

Please also look also to the following example:

  GNU Backgammon  Position ID: sOfgEwDg8+AIBg
  +13-14-15-16-17-18------19-20-21-22-23-24-+     O: gnubg
  | X        X  O    |   | O  O  X          |     0 Points
  | X           O    |   | O  O  X          |     
  | X           O    |   | O                |     
  |                  |   | O                |     
  |                  |   |                  |    
 v|                  |BAR|                  |     (Doppler: 1)
  | O                |   | X                |    
  | O           X    |   | X                |     
  | O           X    |   | X                |     
  | O           X    |   | X                |     At Roll
  | O     O     X    |   | X                |     0 Points
  +12-11-10--9--8--7-------6--5--4--3--2--1-+     X: janek
 Pip counts: O 138, X 159

 This interesting position can be defined with (O is white, X is black)
 
 position => {
     whitepoints => {5 => 2, 6 => 4,  8 => 3, 13 => 5, 15 => 1},
     blackpoints => {6 => 5, 8 => 4, 13 => 3, 16 => 1, 21 => 2},
     atroll      => 'black'
 }
 
The number of checkers at the bar is defined with 
C<'bar' => $nr_of_checkers_at_bar>,
while the number of checkers off the game is defined with
C<'off' => $nr_of_checkers_off>.

The default for the points 1 .. 24 and the bar is 0,
while the default for the checkers off the game is 
C<max(0,15 - sum(all over points)>.

The atroll parameter has to be either 'white' or 'black' (whether upper/lower
case is unimportant) [the default is 'black'].

This method is unfortunately not explicitly tested (only via the 
initialization with new).

=item my %point = $game->whitepoints; my $off = $game->whitepoints('off');

This method returns either the hash with all white points
(including the checkers off the game, if there are someones)
or the number of checkers at a specific point.
The hash is returned when there is no argument specified,
while the number of checkers is returned if the point is passed as argument.
Note that points without a checker are not represented in the hash.

For further details, please read the documentation of C<set_position>.

=item my %point = $game->blackpoints; my $off = $game->blackpoints('off');

Similar to C<whitepoints>.

=item my $atroll = $game->atroll;

Returns the player who is at roll

=back

=head2 EXPORT

None by default.

=head1 BUGS

Please inform me about every one you can find.

=head1 TODO

A lot. I'm working currently on it.

Please feel free to suggest me anything you'll need.
(I will do it on the top of my priority list).

=head1 SEE ALSO

Have also a look to the great open source project gnubg of Gary Wong.

=head1 AUTHOR

Janek Schleicher, E<lt>bigj@kamelfreund.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Janek Schleicher

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
