# Useful Library

*Some useful modules used in my routine work and analysis*

## Installation

Input `git clone http://github.com/kepbod/usefullib.git /path/to/usefullib` on your terminal.  
PS: '/path/to/usefullib' is a random pathway you like.

## Usage

**For Perl Modules**

> Add `use lib "/path/to/usefullib/perl/";` and `use ModuleName qw(Functions...);`
> to your perl scripts.  
> PS: 'ModuleName' and 'Functions' are set according to your needs.

**For Python Modules**

> Add `import sys`, `sys.path.insert(0,'/path/to/usefullib/python/')` and
> `from ModuleName import Class/Function` or `import ModuleName` to your python
> scripts.  
> PS: 'ModuleName' and 'Class/Function' are set according to your needs.

## File Structure

* [perl](https://github.com/kepbod/usefullib/tree/master/perl) - Perl Modules
* [python](https://github.com/kepbod/usefullib/tree/master/python) Python Modules

## Modules

* [Overlap.pm](https://github.com/kepbod/usefullib/blob/master/perl/Overlap.pm): Used to cope with overlaps between arrays  
    Functions: OverlapMax, OverlapMap, OverlapMerge
* [RefFileParse.pm](https://github.com/kepbod/usefullib/blob/master/perl/RefFileParse.pm): Parse reference files  
    Functions: ExtractInfo
* [SAMParse.pm](https://github.com/kepbod/usefullib/blob/master/perl/SAMParse.pm): Parse SAM files  
    Functions: ReadSplit
* [interval.py](https://github.com/kepbod/usefullib/blob/master/python/interval.py): Cope with intervals  
    Class: Interval
* [map.py](https://github.com/kepbod/usefullib/blob/master/python/map.py): Deal with mapping.
    Functions: mapto, overlapwith
* [bpkm.py](https://github.com/kepbod/usefullib/blob/master/python/bpkm.py): Calculate BPKM.
    Functions: calculatebpkm
* [bpkm_new.py](https://github.com/kepbod/usefullib/blob/master/python/bpkm_new.py): Calculate BPKM for SAM file.
* [bpkm_new2.py](https://github.com/kepbod/usefullib/blob/master/python/bpkm_new2.py): Calculate BPKM. Very fast.

## Notice

**All these modules are created and maintained by myself, so if there are some bugs and questions, please feel free to let me know. Thanks!**
