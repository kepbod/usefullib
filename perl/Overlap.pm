#!/usr/bin/perl

package Overlap;

our $AUTHOR = "Xiao'ou Zhang";
our $VERSION = 0.1.0;

use strict;
use warnings;
use 5.010;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(OverlapMax OverlapMap OverlapMerge);

##########Subroutine##########

#
# Name: OverlapMax
# Parameter: \@old_array (or \$old_array, when used $flag_of_sorted will be set 1),
#            $seperator (nonword character) (optional),
#            $flag_of_containing_tag (0 or 1) (optional),
#            $flag_of_sorted (0 or 1) (optional)
# Default Values: $seperator = \s, $flag_of_containing_tag = 0, $flag_of_sorted = 0
# Return: @new_array (return the pointer to @new_array in scalar context)
#         $interval (if the first parameter is \$old_array)
#
# Function: Used to extract the max overlaps from this array.
#
# Example: input '2 5', '3 7', '10 16', '12 13', '6 8'
#          output '2 8', '10 16'
#
# Notice:
# 1.When using \$old_array, it will not sort the array again.
# 2.Remember to return the last interval use \$undef_value when use \$old_array.
#
sub OverlapMax {

    # if in void context
    die "OverlapMax can't in void context!\n" unless defined wantarray;

    # initiate internal parameters
    my ($out_sep, $re_sorted_array, @new_array, $is_array, $status, $first_data);
    state $interval1;

    my $re_old_array = shift; # $re_old_array: \@old_array or \$re_old_array

    # check optional parameters
    # $sep: $seperator, $flag1: $flag_of_containing_tag, $flag2: $flag_of_sorted
    my ($sep, $flag1, $flag2) = _parameter_check('OverlapMax', 3, \@_,
                                [qr(\W), qr(0|1), qr(0|1)], ['\s', 0, 0]);

    # set output_seperator
    _set_sep(\$sep, \$out_sep);

    # check the first parameter
    if (ref $re_old_array eq 'ARRAY') {
        $is_array = 1;
    }
    elsif (ref $re_old_array eq 'SCALAR') {
        # if $old_array is undef, return last interval
        unless (defined $$re_old_array) {
            my $tmp = $interval1;
            $interval1 = undef; # clear $interval1 for next usage
            return $tmp;
        }
        $is_array = 0;
        $status = 'uncomplete'; # initiate status
        $re_old_array = [$$re_old_array];
        $flag2 = 1;
    }
    else {
        die "Errors with OverlapMax 1 parameter!";
    }

    unless ($flag2) { # sort @old_array by its first index if not sorted
        $re_sorted_array = _sort($re_old_array, $sep, 1);
    }
    else { # if sorted
        $re_sorted_array = $re_old_array;
    }

    # shift the first interval as the initiate interval if not initiated
    unless (defined $interval1) {
        $first_data = shift @$re_sorted_array;
        $interval1 = $first_data;
    }
    for my $interval2 (@$re_sorted_array) { # loop if the array is not end
        # if $interval1 and $interval2 have overlaps
        if ((split /$sep/,$interval1)[1] >= (split /$sep/,$interval2)[0]) {
            my $tmp = (split /$sep/,$interval1)[1] > (split /$sep/,$interval2)[1] ?
                      (split /$sep/,$interval1)[1] : (split /$sep/,$interval2)[1];
            if ($flag1) { # if has tags
                $interval1 = (split /$sep/,$interval1)[0] . $out_sep . $tmp .
                             $out_sep . (split /$sep/,$interval1,3)[-1] . $out_sep .
                             (split /$sep/,$interval2,3)[-1];
            }
            else { # if not has tags
                $interval1 = (split /$sep/,$interval1)[0] . $out_sep . $tmp;
            }
        }
        else{ # if there are no overlaps between $interval1 and $interval2
            push @new_array,$interval1;
            unless ($is_array) { # change status when this interval is closed
                $status = $interval1;
            }
            $interval1 = $interval2;
        }
    }
    unshift @$re_sorted_array,$first_data; # recover $old_array
    unless ($is_array) {
        return $status; # return for scalar parameter
    }
    push @new_array,$interval1; # push the last interval into @new_array
    # return new array according to context
    return wantarray ? @new_array : \@new_array;

}

#
# Name: OverlapMap
# Parameter: \@map_to_array (sorted already), \@map_array, (@map_to_array don't
#            contain overlaps and @map_array (don't) contain overlaps)
#            $seperator (nonword character) (optional),
#            $flag_of_containing_tag (00 or 01 or 10 or 11) (optional),
#            $flag_of_sorted (0 or 1) (focus on @map_array) (optional)
# Default Values: $seperator = \s, $flag_of_containing_tag = 11,
#                 $flag_of_sorted = 0
# Return: @mapped_array (return the pointer to @mapped_array in scalar context)
#
# Function: Used to map a messy array to a clean index.
#
# Example: input (1) '3 7 !', '10 12 @', '16 20 #', '23 25 $'
#                (2) '2 4 a', '2 7 b', '2 3 c', '4 11 d', '4 6 e', '5 9 f',
#                    '7 10 g', '15 17 h', '18 21 i', '9 24 x', '13 14 y'
#          output '3 4 ! a', '3 7 ! b', '4 7 ! d', '4 6 ! e', '5 7 ! f',
#                 '10 11 @ d', '10 12 @ x', '16 20 # x', '16 17 # h', '18 20 # i',
#                 '23 24 $ x'
#
# Notice: This function will ruin @map_array, so be careful if using @map_array
#         after calling this function
#
sub OverlapMap {

    # if in void context
    die "OverlapMax can't in void context!\n" unless defined wantarray;

    # initiate internal parameters
    my ($out_sep, $re_sorted_map_array, @mapped_array, $read, @tmp_array);

    my $re_map_to_array = shift; # $re_map_to_array: \@map_to_array
    my $re_map_array = shift; # $re_map_array: \@map_array

    # check optional parameters
    # $sep: $seperator, $flag1: $flag_of_containing_tag, $flag2: $flag_of_sorted
    my ($sep, $flag1, $flag2) = _parameter_check('OverlapMax', 3, \@_,
                                [qr(\W), qr((0|1){1,2}), qr(0|1)],
                                ['\s', '11', '0']);

    # set output_seperator
    _set_sep(\$sep, \$out_sep);

    unless ($flag2) { # sort @map_array by its first index if not sorted
        $re_sorted_map_array = _sort($re_map_array, $sep, 1);
    }
    else { # if sorted
        $re_sorted_map_array = $re_map_array;
    }

    for my $interval (@$re_map_to_array) { # read one index couple
        LABEL:$read = shift @$re_sorted_map_array; # read one read
        unless (defined $read) { # reads have been over
            if (defined $tmp_array[0]) { # exist cut-off reads, shift them
                unshift @$re_sorted_map_array,@tmp_array;
                @tmp_array = ();
                goto LABEL;
            }
            else { last } # exit
        }
        # reads before last index have been over
        if ((split /$sep/,$read)[0] >= (split /$sep/,$interval)[1]) {
            # shift cut-off reads and clean cut-off read array
            unshift @$re_sorted_map_array,$read;
            unshift @$re_sorted_map_array,@tmp_array if defined $tmp_array[0];
            @tmp_array = ();
            next; # read next index couple
        }
        my $first = (split /$sep/,$read)[0] > (split /$sep/,$interval)[0] ?
                (split /$sep/,$read)[0] : (split /$sep/,$interval)[0];
        my $second = (split /$sep/,$read)[1] < (split /$sep/,$interval)[1] ?
                (split /$sep/,$read)[1] : (split /$sep/,$interval)[1];
        if($first >= $second) { # read before the first index
            goto LABEL; # read next read
        }
        my $tag;
        given ($flag1) { # set tag according to flag
            when (00) {$tag = ''; break}
            when (01) {$tag = $out_sep . (split /$sep/,$read)[2]; break}
            when (10) {$tag = $out_sep . (split /$sep/,$interval)[2]; break}
            when (11) {
                $tag = $out_sep . (split /$sep/,$interval)[2] . $out_sep .
                       (split /$sep/,$read)[2];
                break;
            }
        }
        my $tmp = $first . $out_sep . $second . $tag;
        push @mapped_array,$tmp; # output interval
        if ($second == (split /$sep/,$interval)[1]) { # exist over-through read
            if ($second != (split /$sep/,$read)[1]) {
                my $tmp = $second . $out_sep . (split /$sep/,$read,2)[-1];
                push @tmp_array,$tmp;
            }
        }
        goto LABEL; # read next read
    }
    # return new array according to context
    return wantarray ? @mapped_array : \@mapped_array;
}

#
# Name: OverlapMerge
# Parameter: \@array1 (sorted already), \@array2 (sorted already),
#            $seperator (nonword character) (optional),
#            $flag_of_containing_tag (00 or 01 or 10 or 11) (optional),
# Default Values: $seperator = \s, $flag_of_containing_tag = 00,
# Return: @merged_array (return the pointer to @merged_array in scalar context)
#
# Function: Used to merge two index.
#
# Example: input (1) '2 5', '7 9', '11 12', '15 17', '19 25', '27 30'
#                (2) '3 6', '8 12', '14 17'
#          output '3 5', '8 9', '11 12', '15 17', '19 25', '27 30'
#
sub OverlapMerge {

    # if in void context
    die "OverlapMax can't in void context!\n" unless defined wantarray;

    # initiate internal parameters
    my ($out_sep, @merged_array);
    my ($i, $j) = (0, 0); # pointer to these two array

    my $re_array1 = shift; # $re_array1: \@array1
    my $re_array2 = shift; # $re_array2: \@array2

    # check optional parameters
    # $sep: $seperator, $flag1: $flag_of_containing_tag
    my ($sep, $flag1) = _parameter_check('OverlapMerge', 2, \@_,
                        [qr(\W), qr((0|1){1,2})], ['\s', '00']);

    # set output_seperator
    _set_sep(\$sep, \$out_sep);

    while (1) {
        my ($interval1, $interval2) = ($$re_array1[$i], $$re_array2[$j]);
        my $first = (split /$sep/,$interval1)[0] > (split /$sep/,$interval2)[0] ?
                (split /$sep/,$interval1)[0] : (split /$sep/,$interval2)[0];
        my $second = (split /$sep/,$interval1)[1] < (split /$sep/,$interval2)[1] ?
                (split /$sep/,$interval1)[1] : (split /$sep/,$interval2)[1];
        if ((split /$sep/,$interval1)[1] == $second) {
            $i++; # point to next element
        }
        if ((split /$sep/,$interval2)[1] == $second) {
            $j++; # point to next element
        }
        if($first < $second) {
            my $tag;
            given ($flag1) { # set tag according to flag
                when (00) {$tag = ''; break}
                when (01) {$tag = $out_sep . (split /$sep/,$interval2)[2]; break}
                when (10) {$tag = $out_sep . (split /$sep/,$interval1)[2]; break}
                when (11) {
                    $tag = $out_sep . (split /$sep/,$interval1)[2] . $out_sep .
                        (split /$sep/,$interval2)[2];
                    break;
                }
            }
            my $tmp = $first . $out_sep . $second . $tag;
            push @merged_array,$tmp;
        }
        if ($i > $#{$re_array1}) { # if @array1 over
            if (defined $$re_array2[$j]) {
                push @merged_array,@{$re_array2}[$j..$#{$re_array2}];
                last;
            }
        }
        if ($j > $#{$re_array2}) { # if @array2 over
            if (defined $$re_array1[$i]) {
                push @merged_array,@{$re_array1}[$i..$#{$re_array1}];
                last;
            }
        }
    }
    # return new array according to context
    return wantarray ? @merged_array : \@merged_array;
}

##########Internal Subroutine##########

#
# Check parameters imported from outside.
#
sub _parameter_check {
    my ($subroutine, $n, $re_old_parameter, $re_value, $re_default) = @_;
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
                die "Errors with $subroutine optional parameter $pos \n";
            }
        }
    }
    return @new_parameter;
}

#
# Sort array according to indexes
#
sub _sort {
    my ($re_array, $sep, $flag) = @_;
    my @sorted_array;
    if ($flag == 1) { # sort by the first index
        @sorted_array = sort { (split /$sep/,$a)[0] <=> (split /$sep/,$b)[0] }
                             @$re_array;
    }
    elsif ($flag == 2) { # sort by the first and the second indexes
        @sorted_array = sort { (split /$sep/,$a)[0] <=> (split /$sep/,$b)[0] or
                               (split /$sep/,$a)[1] <=> (split /$sep/,$b)[1] }
                             @$re_array;
    }
    else { # the flag is wrong
        die "Errors occure when sorting!\n";
    }
    return \@sorted_array;
}

#
# Set seperator
#
sub _set_sep {
    my ($re_sep, $re_out_sep) = @_;
    $$re_out_sep = $$re_sep;
    if ($$re_out_sep eq '\s') {
        $$re_out_sep = ' ';
    }
    my %tra_dic = ('.' => '\.', '+' => '\+', '?' => '\?', '*' => '\*', '|' => '\|');
    if (exists $tra_dic{$$re_sep}) {
        $$re_sep = $tra_dic{$$re_sep};
    }
}

1;
