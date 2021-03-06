#!/usr/bin/env python3
'''
bpkm.py - Calculate BPKM.
author: Xiao-Ou Zhang
version: 0.2.0
'''

import sys
sys.path.insert(0, '/picb/rnomics1/xiaoou/program/usefullib/python')
from map import mapto
from subprocess import Popen, PIPE
import os


def calculatebpkm(chrom, sta, end, bam, total=0, length=0, getsegment=False):
    '''
    calculatebpkm(chrom, sta, end, bam, total, length, getsegment) -> bpkm
    Calculate BPKM.
    '''
    sta = int(sta)
    end = int(end)
    total = int(total)
    length = int(length)
    if sta == end:
        return 0
    read_segments = []
    with Popen(['samtools', 'view', bam, '{}:{}-{}'.format(chrom, sta, end)],
            stdout=PIPE) as proc:
        for line in proc.stdout:
            str_line = line.decode('utf-8')
            pos = str_line.split()[3]
            cigar = str_line.split()[5]
            segment = readsplit(pos, cigar)
            read_segments.extend(segment)
    if not read_segments:
        return 0
    mapped_read_segments = mapto(read_segments, [[sta, end]])
    if not getsegment:
        base = 0
        for segment in mapped_read_segments:
            base += segment[1] - segment[0]
        return (base * pow(10, 9)) / (total * length * (end - sta))
    else:
        return mapped_read_segments


def readsplit(pos1, cigar):
    '''
    readsplit(pos, cigar) -> interval
    Split reads.
    '''
    pos2, num = (int(pos1), '')
    interval = []
    for i in cigar:
        if 48 <= ord(i) <= 57:
            num += i
            continue
        elif i == 'M' or i == 'D':
            pos2 += int(num)
            num = ''
            continue
        elif i == 'I':
            num = ''
            continue
        elif i == 'N':
            interval.append([int(pos1), pos2])
            pos1 = pos2 + int(num)
            pos2 = pos1
            num = ''
    interval.append([int(pos1), pos2])
    return interval

if __name__ == '__main__':
    if len(sys.argv) != 4:
        print('bpkm.py *.bed *.bam length')
        sys.exit(0)
    name = os.path.splitext(os.path.split(sys.argv[1])[1])[0]
    bam, length = sys.argv[2:5]
    size = 0
    with Popen(['samtools', 'idxstats', bam], stdout=PIPE) as proc:
        for line in proc.stdout:
            str_line = line.decode('utf-8')
            size += int(str_line.split()[2])
    with open(sys.argv[1], 'r') as f:
        with open('{}.bpkm'.format(name), 'w') as outf:
            for line in f:
                chrom, sta, end, *remaining = line.split()
                bpkm = calculatebpkm(chrom, sta, end, bam, size, length)
                pos = '{}:{}-{}'.format(chrom, sta, end)
                result = '\t'.join([pos, str(bpkm)] + remaining)
                outf.write('{}\n'.format(result))
