'''
title: map.py
description: Deal with mapping.
author: Xiaoou Zhang
version: 0.1.0
'''

import copy


class Map:
    def __init__(self, interval):
        self.mapping = [[int(i[0]), int(i[1])] + i[2:] for i in interval]
        self.mapping.sort()

    def __map(index, interval, flag):
        mapped_fragment = []
        tmp_fragment = []
        if not interval:
            if flag:
                return mapped_fragment
            else:
                return index
        for dex in index:
            dex_info = dex[2:]
            while True:
                try:
                    fragment = interval.pop(0)
                except IndexError:
                    if tmp_fragment:
                        interval.extend(tmp_fragment)
                        continue
                    else:
                        if flag:
                            return mapped_fragment
                        else:
                            return index
                if fragment[0] >= dex[1]:
                    interval.insert(0, fragment)
                    interval[0:0] = tmp_fragment
                    tmp_fragment = []
                    break
                elif dex[0] < fragment[1] and dex[1] > fragment[0]:
                    dex += fragment[2:]
                    sta = dex[0] if dex[0] > fragment[0] else fragment[0]
                    end = dex[1] if dex[1] < fragment[1] else fragment[1]
                    new_fragment = [sta, end] + fragment[2:] + dex_info
                    mapped_fragment.append(new_fragment)
                    if fragment[1] > dex[1]:
                        tmp_fragment.append([dex[1],
                                fragment[1]] + fragment[2:])
        else:
            if flag:
                return mapped_fragment
            else:
                return index

    def mapto(self, interval):
        if isinstance(interval, Map):
            tmp = copy.deepcopy(interval.mapping)
        else:
            tmp = Map(interval).mapping
        self.mapping = Map.__map(tmp, self.mapping, flag=1)

    def overlapwith(self, interval):
        if isinstance(interval, Map):
            tmp = copy.deepcopy(interval.mapping)
        else:
            tmp = Map(interval).mapping
        self.mapping = Map.__map(self.mapping, tmp, flag=0)
