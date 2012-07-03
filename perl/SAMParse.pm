package SAMParse;

#
# Module Name: SAMParse.pm
# Function: Parse SAM files.
#

use strict;
use warnings;
use Carp;

our $AUTHOR = "Xiaoou Zhang";
our $VERSION = "0.1.0";

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(ReadSplit);

##########Subroutine##########

#
# Name: ReadSplit
# Parameter: $position, $cigar, $seperator (optional), $flag (optional)
# Default: $seperator = \s
# Return: \@intervals
#
# Function: Convert the read into split segments.
#
# Example: MMMMMMIIIMMMMMMMNNNNNNNNNNMMMMMMDDDMMMMMMMNNNNNNMMMMMMM
#          ^     ***       ^         ^               ^     ^      ^
#          1               1         2               2     3      3
#
sub ReadSplit {

    # if in void context
    croak "ReadSplit can't in void context!" unless defined wantarray;

    # cope with parameters
    my $pos1 = shift; # $pos1: $position
    my $cigar = shift;

    # check optional parameters
    my ($sep, $flag) = _parameter_check(2, \@_,
                       [qr(\W), qr(.*)], ['\s', '']);
    if ($flag) {
        $flag = $sep . $flag;
    }

    # initiate parameters
    my ($pos2, $num) = ($pos1, '');
    my (@intervals);

    foreach my $c (split //,$cigar) {
        if ($c =~ /\d/) { # if it's numeric
            $num .= $c;
            next;
        }
        if ($c =~ /M|D/) { # if it's Match/Delete
            $pos2 += $num;
            $num = '';
            next;
        }
        if ($c =~ /I/) { # if it's Insert
            $num = '';
            next;
        }
        if ($c =~ /N/) { # it it's NaN
            push @intervals,$pos1 . $sep . $pos2 . $flag;
            $pos1 = $pos2 + $num;
            $pos2 = $pos1;
            $num = '';
        }
    }
    push @intervals,$pos1 . $sep . $pos2 . $flag unless $pos1 == $pos2;
    return \@intervals;
}

##########Internal Subroutine##########

#
# Function: Check parameters imported from outside.
#
sub _parameter_check {
    my ($n, $re_old_parameter, $re_value, $re_default) = @_;
    my @new_parameter;
    for (0..$n-1) {
        if (!defined $$re_old_parameter[$_]) { # no parameter, use default instead
            push @new_parameter,$$re_default[$_];
        }
        else {
            push @new_parameter,$$re_old_parameter[$_]; # has parameter, use it
            # check parameter value
            unless ($$re_old_parameter[$_] =~ $$re_value[$_]) {
                my $pos = $_ + 1;
                my $subroutine = (caller 1)[3];
                croak "Errors with $subroutine optional parameter $pos!";
            }
        }
    }
    return @new_parameter;
}

1;
