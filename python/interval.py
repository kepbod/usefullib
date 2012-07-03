#!/usr/bin/env python3

'''
title: interval.py
description: Cope with intervals.
author: Xiaoou Zhang
version: 0.1.0
'''

import copy


class Interval:
    '''
    Class: Interval

    Maintainer: Xiaoou Zhang

    Version: 0.1.0

    Usage: a = Interval(list)
           (list: [[x,x,f1...],[x,x,f2...]...] / [[x,x],[x,x]...])
    Notes: all the intervals in the list will become mutually exclusive and
           be sorted after instantiation.

    Attributes: interval

    Functions: c = a + b or a += b
               c = a * b or a *= b
               c = a - b or a -= b
               a.complement([sta, end])
               a.overlapwith(b)
               a.overlapwithout(b)
    '''
    def __init__(self, interval, instance_flag=0):
        self.interval = interval
        if not instance_flag:
            self.interval.sort()
            tmp = []
            a = self.interval[0]
            for b in self.interval[1:]:
                if a[1] <= b[0]:
                    tmp.append(a)
                    a = b
                else:
                    a[1] = b[1] if b[1] > a[1] else a[1]
                    a.extend(b[2:])
            tmp.append(a)
            self.interval = tmp

    def __add__(self, interval):
        '''
        Usage: c = a + b
        extract union intervals, 'a' should be instance.
        '''
        tmp = copy.deepcopy(self.interval)
        if isinstance(interval, Interval):
            tmp.extend(interval.interval)
        else:
            tmp.extend(interval)
        return Interval(tmp)

    def __iadd__(self, interval):
        '''
        Usage: a += b
        extract union intervals, 'a' should be instance.
        '''
        return Interval.__add__(self, interval)

    def __mul__(self, interval, real_flag=1):
        '''
        Usage: c = a * b
        extract intersection intervals, 'a' should be instance.
        '''
        tmp = []
        tmp1 = copy.deepcopy(self.interval)
        if isinstance(interval, Interval):
            tmp2 = copy.deepcopy(interval.interval)
        else:
            tmp2 = copy.deepcopy(Interval(interval).interval)
        a, b = tmp1.pop(0), tmp2.pop(0)
        while True:
            sta = a[0] if a[0] > b[0] else b[0]
            end = a[1] if a[1] < b[1] else b[1]
            if sta < end:
                if real_flag:
                    tmp.append([sta, end] + a[2:] + b[2:])
                else:
                    tmp.append(a)
            if a[1] == end:
                try:
                    a = tmp1.pop(0)
                except IndexError:
                    break
            if b[1] == end:
                try:
                    b = tmp2.pop(0)
                except IndexError:
                    break
        return Interval(tmp, 1)

    def __imul__(self, interval):
        '''
        Usage: a *= b
        extract intersection intervals, 'a' should be instance.
        '''
        return Interval.__mul__(self, interval)

    def __sub__(self, interval, real_flag=1):
        '''
        Usage: c = a - b
        extract difference intervals, 'a' should be instance.
        '''
        tmp1 = copy.deepcopy(self)
        if isinstance(interval, Interval):
            tmp2 = copy.deepcopy(interval)
        else:
            tmp2 = copy.deepcopy(Interval(interval))
        if tmp1.interval[0][0] < tmp2.interval[0][0]:
            sta = tmp1.interval[0][0]
        else:
            sta = tmp2.interval[0][0]
        if tmp1.interval[-1][1] > tmp2.interval[-1][1]:
            end = tmp1.interval[-1][1]
        else:
            end = tmp2.interval[-1][1]
        tmp2.complement(sta, end)
        return Interval.__mul__(tmp1, tmp2, real_flag)

    def __isub__(self, interval):
        '''
        Usage: a -= b
        extract difference intervals, 'a' should be instance.
        '''
        return Interval.__sub__(self, interval)

    def complement(self, sta='#', end='#'):
        '''
        Usage: a.complement([sta, end])
        complement of 'a'.
        '''
        tmp = []
        if sta != '#' and sta < self.interval[0][0]:
            tmp.append([sta, self.interval[0][0]])
        a = self.interval[0][1]
        for item in self.interval[1:]:
            b = item[0]
            tmp.append([a, b])
            a = item[1]
        if end != '#' and end > a:
            tmp.append([a, end])
        self.interval = tmp

    def overlapwith(self, interval):
        '''
        Usage: a.overlapwith(b)
        extract intervals in 'b'.
        '''
        self.interval = Interval.__mul__(self, interval, 0).interval

    def overlapwithout(self, interval):
        '''
        Usage: a.overlapwithout(b)
        extract intervals not in 'b'.
        '''
        self.interval = Interval.__sub__(self, interval, 0).interval
