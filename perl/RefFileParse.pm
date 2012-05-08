package RefFileParse;

#
# Module Name: RefFileParse.pm
# Function: Parse reference file.
#

use strict;
use warnings;
use Carp;

our $AUTHOR = "Xiao'ou Zhang";
our $VERSION = "0.3.0";

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(ExtractInfo);

##########Subroutine##########

#
# Schema of refFlat:
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
# Schema of knownGene:
#
# uc001aaa.3      chr1    +       11873   14409   11873   11873     3
#   Name         chrom  strand   tx_sta  tx_end  cds_sta cds_end exon_num
#    0             1      2         3       4       5       6       7
# 11873,12612,13220,      12227,12721,14409,                 uc001aaa.3
#      exon_sta                exon_end          ProteinID     AlignID
#         8                       9                 10            11
#

#
# Name: ExtractInfo
# Parameter: $file (file handle of RefFile), $name,
#            $chr (optional), $sep (optional), $flag_of_gene_info (optional),
#            $flag_of_gene_index (optional), $flag_of_excluding_sole_exon (optional)
# Default Values: $chr='all', $sep = '-', $flag_of_gene_info = 0
#                 $flag_of_gene_index = 0, $flag_of_excluding_sole_exon = 0
# Return: \@tx_sta_end, \@cds_sta_end, \@exon_sta_end (if $flag_of_gene_index = 0)
#         \%exon_sta_end (if $flag_of_gene_index = 1)
#
# Function: Extract info from reference file
#
# Notice: If you don't want to indicate chr, please input "all" instead.
#         If $flag_of_gene_info is 0, then $flag_of_gene_index and
#         $flag_of_excluding_sole_exon will be set to 0 automatically.
#
sub ExtractInfo {

    # if in void context
    croak "ExtractInfo can't in void context!\n" unless defined wantarray;

    my $file = shift;
    my $filename = shift;

    my ($chr, $sep, $flag_of_gene_info, $flag_of_gene_index,
        $flag_of_excluding_sole_exon)
        = _parameter_check(5, \@_, [qr(chr([0-9]{1,2}|X|Y|M)|all),
            qr(\W), qr(0|1), qr(0|1), qr(0|1)], ['all', '-', '0', '0', '0']);

    if ($flag_of_gene_info == 0) {
        $flag_of_gene_index = 0;
        $flag_of_excluding_sole_exon = 0;
    }

    my (@gene_sta_end, @cds_sta_end, @exon_sta_end, %exon_sta_end);

    while (<$file>) {

        chomp;
        my ($genename, $txname, $chrom, $strand, $txsta, $txend, $cdssta,
            $cdsend, $exonnum, $exonsta, $exonend)
            = _linesplit($filename, $_);
        my @single_gene_exon_sta_end;

        if ($chr ne 'all') {
            next if $chr ne $chrom;
        }

        if (!$flag_of_gene_index) {
            $genename =~ s/-/#/g;
            my $info = $flag_of_gene_info ? "$sep$genename" : '';
            push @gene_sta_end,$txsta . $sep . $txend . $info;
            push @cds_sta_end,$cdssta . $sep . $cdsend . $info;
        }
        else{
            next if $flag_of_excluding_sole_exon and $exonnum == 1;
        }

        my @exonsta = split /,/,$exonsta;
        my @exonend = split /,/,$exonend;
        for (0..$exonnum-1) {
            push @single_gene_exon_sta_end,$exonsta[$_] . $sep . $exonend[$_];
        }

        if (!$flag_of_gene_index) {
            push @exon_sta_end,@single_gene_exon_sta_end;
        }
        else {
            my $info = $chrom . ':' . $genename;
            if (exists $exon_sta_end{$info}) {
                push @{$exon_sta_end{$info}},@single_gene_exon_sta_end;
            }
            else {
                $exon_sta_end{$info} = \@single_gene_exon_sta_end;
            }
        }

    }
    close $file;

    if (!$flag_of_gene_index) {
        return (\@gene_sta_end, \@cds_sta_end, \@exon_sta_end);
    }
    else {
        return (\%exon_sta_end)
    }

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

#
# Function: Split lines according to file name.
#
sub _linesplit {
    my $filename = shift;
    my $line = shift;
    my ($genename, $txname, $chrom, $strand, $txsta, $txend, $cdssta, $cdsend,
        $exonnum, $exonsta, $exonend);
    if ($filename eq 'refFlat') {
        ($genename, $txname, $chrom, $strand, $txsta, $txend, $cdssta, $cdsend,
        $exonnum, $exonsta, $exonend) = split /\s/,$line;
    }
    elsif ($filename eq 'knownGene') {
        ($genename, $chrom, $strand, $txsta, $txend, $cdssta, $cdsend,
        $exonnum, $exonsta, $exonend) = (split /\s/,$line)[0..9];
    }
    else {
        croak "Can't parse $filename file!\n";
    }
    return ($genename, $txname, $chrom, $strand, $txsta, $txend, $cdssta,
            $cdsend, $exonnum, $exonsta, $exonend);
}

1;
