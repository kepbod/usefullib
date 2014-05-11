#!/usr/bin/env python3
'''
bpkm_new.py - Calculate BPKM.
author: Xiao-Ou Zhang
version: 0.3.0
'''

import sys
sys.path.insert(0, '/picb/rnomics1/xiaoou/program/usefullib/python')
from map import mapto
import os


def calculatebpkm(index, read, chrom, total, length, out):
    total = int(total)
    length = int(length)
    mapped_read_segments = mapto(read, index)
    interval = {}
    for i in mapped_read_segments:
        if i[2] in interval:
            interval[i[2]] += i[1] - i[0]
        else:
            interval[i[2]] = i[1] - i[0]
    for i in index:
        sta, end = i[0:2]
        sta = int(sta)
        end = int(end)
        if i[2] in interval:
            bpkm = interval[i[2]] * pow(10, 9) / (total * length * (end - sta))
            out.write('{}:{}-{}\t{}\n'.format(chrom, sta, end, bpkm))
        else:
            out.write('{}:{}-{}\t{}\n'.format(chrom, sta, end, 0))


def readsplit(pos1, cigar):
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
    if len(sys.argv) != 5:
        print('bpkm_new.py *.bed *.sam size length')
        sys.exit(0)
    name = os.path.splitext(os.path.split(sys.argv[1])[1])[0]
    size, length = sys.argv[3:5]
    index = {'chr' + str(i): [] for i in list(range(1, 23)) + ['X', 'Y']}
    read = {'chr' + str(i): [] for i in list(range(1, 23)) + ['X', 'Y']}
    chrom_list = ['chr' + str(i) for i in list(range(1, 23)) + ['X', 'Y']]
    with open('{}.bpkm'.format(name), 'w') as outf:
        with open(sys.argv[1], 'r') as f:
            print('read bed...')
            for line in f:
                chrom, sta, end = line.split()[0:3]
                index[chrom].append([sta, end, sta + '-' + end])
        with open(sys.argv[2], 'r') as f:
            print('read sam...')
            for line in f:
                chrom, pos = line.split()[2:4]
                if chrom not in chrom_list:
                    continue
                cigar = line.split()[5]
                segment = readsplit(pos, cigar)
                read[chrom].extend(segment)
        for i in list(range(1, 23)) + ['X', 'Y']:
            chrom = 'chr' + str(i)
            print('deal with {}...'.format(chrom))
            bpkm = calculatebpkm(index[chrom], read[chrom], chrom, size,
                                length, outf)
