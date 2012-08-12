'''
map.py - Deal with mapping.
author: Xiaoou Zhang
version: 0.2.0
'''


def __init(interval):
    mapping = [[int(i[0]), int(i[1])] + i[2:] for i in interval]
    mapping.sort()
    return mapping


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


def mapto(interval, index):
    '''
    mapto(interval, index) -> interval
    Map interval onto index.
    '''
    tmp1 = __init(interval)
    tmp2 = __init(index)
    return __map(tmp2, tmp1, flag=1)


def overlapwith(index, interval):
    '''
    overlapwith(index, interval) -> index
    Overlap index with interval.
    '''
    tmp1 = __init(index)
    tmp2 = __init(interval)
    return __map(tmp1, tmp2, flag=0)
