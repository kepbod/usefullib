package RefFileParse;

#
# Module Name: RefFileParse.pm
# Function: Parse reference files.
#

use strict;
use warnings;
use Carp;

our $AUTHOR = "Xiao-Ou Zhang";
our $VERSION = "0.5.0";

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
# Return: \@tx_sta_end, \@cds_sta_end, \@exon_sta_end, \@intron_sta_end (if $flag_of_gene_index = 0)
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
    croak "ExtractInfo can't in void context!" unless defined wantarray;

    # use filename to distinguish different reference files
    my $file = shift;
    my $filename = shift;

    # check optional parameters
    my ($chr, $sep, $flag_of_gene_info, $flag_of_gene_index,
        $flag_of_excluding_sole_exon)
        = _parameter_check(5, \@_, [qr(chr([0-9]{1,2}|X|Y|M)|all),
            qr(\W), qr(0|1), qr(0|1), qr(0|1)], ['all', '-', '0', '0', '0']);

    # if not need gene info, other parameters about gene will be set 0 automatically
    if ($flag_of_gene_info == 0) {
        $flag_of_gene_index = 0;
        $flag_of_excluding_sole_exon = 0;
    }

    # initiate parameters
    my (@gene_sta_end, @cds_sta_end, @exon_sta_end, @intron_sta_end, %exon_sta_end);

    while (<$file>) { # read file

        chomp;
        # get info according to file schema
        my ($genename, $txname, $chrom, $strand, $txsta, $txend, $cdssta,
            $cdsend, $exonnum, $exonsta, $exonend)
            = _linesplit($filename, $_);
        my (@single_gene_exon_sta_end, @single_gene_intron_sta_end);

        if ($chr ne 'all') { # if indicate chr info
            next if $chr ne $chrom;
        }

        # set gene info
        $genename =~ s/-/#/g; # substitute '-' with '#' in case split errors
        my $info = $flag_of_gene_info ? "$sep$genename" : '';

        if (!$flag_of_gene_index) {
            push @gene_sta_end,$txsta . $sep . $txend . $info;
            push @cds_sta_end,$cdssta . $sep . $cdsend . $info;
        }
        else{
            # exclude sole exon according to flag
            next if $flag_of_excluding_sole_exon and $exonnum == 1;
        }

        # get exon info
        my @exonsta = split /,/,$exonsta;
        my @exonend = split /,/,$exonend;
        for (0..$exonnum-1) { # exon edge 
            push @single_gene_exon_sta_end,$exonsta[$_] . $sep . $exonend[$_] .  $info;
        }
        for (1..$exonnum-1) { # intron edge 
            next if $exonend[$_ - 1] == $exonsta[$_];
            push @single_gene_intron_sta_end,$exonend[$_ - 1] . $sep .  $exonsta[$_] . $info;
        }

        if (!$flag_of_gene_index) {
            push @exon_sta_end,@single_gene_exon_sta_end;
            push @intron_sta_end,@single_gene_intron_sta_end;
        }
        else {
            # use chr and gene name together in case two same genes in different chromosomes
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

    # output according to flags
    if (!$flag_of_gene_index) {
        return (\@gene_sta_end, \@cds_sta_end, \@exon_sta_end, \@intron_sta_end);
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
                croak "Errors with $subroutine optional parameter $pos!";
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
        $exonnum, $exonsta, $exonend) = split /\t/,$line;
    }
    elsif ($filename eq 'knownGene') {
        ($genename, $chrom, $strand, $txsta, $txend, $cdssta, $cdsend,
        $exonnum, $exonsta, $exonend) = (split /\t/,$line)[0..9];
    }
    else {
        croak "Can't parse $filename file!";
    }
    return ($genename, $txname, $chrom, $strand, $txsta, $txend, $cdssta,
            $cdsend, $exonnum, $exonsta, $exonend);
}

1;
