#!/usr/bin/env python
'''
bpkm_new2.py - Calculate BPKM.
author: Xiaoou Zhang
version: 0.3.0
'''

import sys
import pysam
import os


def calculatebpkm(chrom, sta, end, bamf, total, length):
    '''
    calculatebpkm(chrom, sta, end, bamf, total, length) -> bpkm
    Calculate BPKM.
    '''
    sta = int(sta)
    end = int(end)
    total = int(total)
    length = int(length)
    if sta == end:
        return 0
    base = 0
    for alignedread in bamf.fetch(chrom, sta, end):
        base += alignedread.overlap(sta, end)
    if not base:
        return 0
    return (base * pow(10, 9)) * 1.0 / (total * length * (end - sta))


if __name__ == '__main__':
    if len(sys.argv) != 4:
        print 'bpkm_new2.py *.bed *.bam length'
        sys.exit(0)
    name = os.path.splitext(os.path.split(sys.argv[1])[1])[0]
    bam, length = sys.argv[2:4]
    f = open(sys.argv[1], 'r')
    bamf = pysam.Samfile(bam, 'rb')
    size = bamf.mapped
    outf = open('%s.bpkm' % (name), 'w')
    for line in f:
        chrom, sta, end = line.split()[0:3]
        bpkm = calculatebpkm(chrom, sta, end, bamf, size, length)
        pos = '%s:%s-%s' % (chrom, sta, end)
        result = '\t'.join([pos, str(bpkm)])
        outf.write('%s\n' % (result))
    f.close()
    bamf.close()
    outf.close()
