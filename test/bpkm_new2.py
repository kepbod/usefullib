#!/usr/bin/env python
'''
bpkm_new2.py - Calculate BPKM.
author: Xiao-Ou Zhang
version: 0.3.0
'''

import sys
import pysam
import os
import fnmatch


def calculatebpkm(chrom, sta, end, bamf, total, length, flag):
    '''
    calculatebpkm(chrom, sta, end, bamf, total, length, flag) -> bpkm
    Calculate BPKM.
    '''
    total = int(total)
    length = int(length)
    base = 0
    isoform_length = 0
    if flag:
        sta = int(sta)
        end = int(end)
        isoform_length = end - sta
        if sta == end:
            return 0
        for alignedread in bamf.fetch(chrom, sta, end):
            base += alignedread.overlap(sta, end)
    else:
        for (s, e) in zip(sta.split(',')[:-1], end.split(',')[:-1]):
            isoform_length += int(e) - int(s)
            for alignedread in bamf.fetch(chrom, int(s), int(e)):
                base += alignedread.overlap(int(s), int(e))
    if not base:
        return 0
    return (base * pow(10, 9)) * 1.0 / (total * length * isoform_length)


if __name__ == '__main__':
    if len(sys.argv) != 4:
        print('bpkm_new2.py *.bed/*.txt *.bam length')
        sys.exit(0)
    name1 = os.path.splitext(os.path.split(sys.argv[1])[1])[0]
    name2 = os.path.splitext(os.path.split(sys.argv[2])[1])[0]
    bam, length = sys.argv[2:4]
    f = open(sys.argv[1], 'r')
    bamf = pysam.Samfile(bam, 'rb')
    size = bamf.mapped
    outf = open('%s_%s.bpkm' % (name1, name2), 'w')
    if fnmatch.fnmatch(sys.argv[1], '*.bed'):
        flag = 1
    else:
        flag = 0
    for line in f:
        if flag:
            chrom, sta, end = line.split()[0:3]
            name = line.split()[3] if len(line.split()) > 3 else ''
            bpkm = calculatebpkm(chrom, sta, end, bamf, size, length, 1)
            pos = name + '\t' if name != '' else ''
            pos += '%s:%s-%s' % (chrom, sta, end)
        else:
            chrom = line.split()[1]
            sta, end = line.split()[6:8]
            bpkm = calculatebpkm(chrom, sta, end, bamf, size, length, 0)
            pos = line.rstrip()
        result = '\t'.join([pos, str(bpkm)])
        outf.write('%s\n' % (result))
    f.close()
    bamf.close()
    outf.close()
