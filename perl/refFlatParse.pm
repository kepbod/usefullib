package refFlatParse;

#
# Module Name: refFlatParse.pm
# Function:
#

use strict;
use warnings;
use Carp;

our $AUTHOR = "Xiao'ou Zhang";
our $VERSION = "0.1.0";

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(ExtractInfo);

##########Subroutine##########

#
# Format of refFlat:
#
# C17orf76-AS1     NR_027160     chr17     +      16342300 16345340
# GeneName      TranscriptID     chrom   strand    tx_sta   tx_end
#    0                1            2       3         4        5
# 16345340         16345340      5
# cds_sta          cds_end    exon_num
#    6                7          8
# 16342300,16342894,16343498,16344387,16344681,
#                   exon_sta
#                      9
# 16342728,16343017,16343567,16344444,16345340,
#                   exon_end
#                      10
#

# Name: ExtractInfo
# Parameter: $file (file handle of refFlat)
#            $chr (optional), $sep (optional)
# Default Values: $chr='all', $sep = '-'
# Return: \@tx_sta_end, \@cds_sta_end, \@exon_sta_end
#
# Function: Extract the start and end point of genes
#
# Example: C17orf76-AS1, NR_027160, chr17, +, 16342300-16345340
#          16345340-16345340, 5, 16342300-16342728, 16342894-16343017,
#          16343498-16343567, 16344387-16344444, 16344681-16345340
#
# Notice: If you don't want to indicate chr, please input "all" instead.
#
sub ExtractInfo {

    # if in void context
    croak "ExtractInfo can't in void context!\n" unless defined wantarray;

    my $file = shift;

    my ($chr, $sep) = _parameter_check(2, \@_, [qr(chr([0-9]{1,2}|X|Y)|all),
                      qr(\W)], ['all','-']);

    my (@gene_sta_end, @cds_sta_end, @exon_sta_end);
    while (<$file>) {
        chomp;
        my @line = split;
        if ($chr ne 'all') {
            next if $chr ne $line[2];
        }
        push @gene_sta_end,$line[4] . $sep . $line[5];
        push @cds_sta_end,$line[6] . $sep . $line[7];
        my @exonsta = split /,/,$line[9];
        my @exonend = split /,/,$line[10];
        for (0..$line[8]-1) {
            push @exon_sta_end,$exonsta[$_] . $sep . $exonend[$_];
        }
    }
    close $file;
    return (\@gene_sta_end, \@cds_sta_end, \@exon_sta_end)

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
                croak "Errors with $subroutine optional parameter $pos \n";
            }
        }
    }
    return @new_parameter;
}

1;
