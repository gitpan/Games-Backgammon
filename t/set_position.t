#!/usr/bin/perl

use strict;
use warnings;

use Games::Backgammon;

use Test::More tests => 131;
use Test::Differences;
use Test::Exception;
use Test::Warn;

use Data::Dumper;

use constant IDEAL_40 => {3 => 1, 4 => 1, 5 => 3, 6 => 3};
use constant IDEAL_79 => {4 => 3, 5 => 5, 6 => 7};

use constant CHECKER_AT_SAME_POINTS => 
    {whitepoints => {1 => 1}, blackpoints => {24 => 1}, atroll => 'black'};
use constant NEITHER_BLACK_OR_WHITE_AT_ROLL => 
    {whitepoints => {1 => 1}, blackpoints => {1 => 1},  atroll=> 'X'};
use constant TWENTY_CHECKERS => {
    whitepoints => {1 => 1, 2 => 19},
    blackpoints => {6 => 1},
    atroll      => 'black'
};

use constant DEFAULT_BOARDS => (
    {whitepoints => {off => 15}, blackpoints => {off => 15}, atroll => 'black'},
    {whitepoints => {},          blackpoints => {},          atroll => 'black'},
    {whitepoints => {off => 15}, blackpoints => {off => 15}},
    {atroll => 'black'},
    {},
);

foreach my $atroll ('BLACK', 'WHITE') {

    my $game = Games::Backgammon->new(
        position => {
          whitepoints => {%{IDEAL_40()}, bar => 1},
          blackpoints => IDEAL_79(),
          atroll      => $atroll
        }
    );
    
    eq_or_diff {$game->whitepoints}, 
               {off => 15-9, bar => 1, %{IDEAL_40()}}, 
               "White points in ideal 40";
    eq_or_diff {$game->blackpoints}, 
               IDEAL_79,
               "Black points in ideal 79";

    is $game->atroll, lc($atroll), "$atroll was at roll and should be lc now";

    my %white = $game->whitepoints;
    my %black = $game->blackpoints;

    for (1 .. 24, 'off', 'bar') {
        is $game->whitepoints($_), ($white{$_} || 0), "Point $_ of white";
        is $game->blackpoints($_), ($black{$_} || 0), "Point $_ of black";
    }
      
}

foreach my $pos (DEFAULT_BOARDS) {
    my $game = Games::Backgammon->new(position => $pos);
    eq_or_diff {$game->whitepoints}, {off => 15}, "White points at default";
    eq_or_diff {$game->blackpoints}, {off => 15}, "Black points at default";
    is $game->atroll, 'black', "Black is at roll by default";
}

for (CHECKER_AT_SAME_POINTS, NEITHER_BLACK_OR_WHITE_AT_ROLL) {
    dies_ok {Games::Backgammon->new(position => $_)} "Should die ..."
    or diag "Should die with " . Dumper($_);
}

dies_ok {Games::Backgammon->new(position => {whitepoints => {blabla => 1}})}
        "Should die with unkown points";

warning_like {Games::Backgammon->new(position => TWENTY_CHECKERS)}
             {carped => qr/15|fifteen/},
             "More than 15 checkers should produce a warning";

{
    local $SIG{__WARN__} = sub { };
    my $game = Games::Backgammon->new(position => TWENTY_CHECKERS);
    is $game->whitepoints('off'), 0, "With twenty checkers in game exactly 0 are off";
    is $game->blackpoints('off'),14, "The other has all but 1 off => 14 off";
}
