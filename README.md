# Useful Library

*Some useful modules used in my routine work and analysis*

## Installation

```bash
git clone http://github.com/kepbod/usefullib.git /path/to/usefullib
```

'/path/to/usefullib' is a random pathway you like.

## Usage

**For Perl Modules**

> Add `use lib "/path/to/usefullib/perl/";` and `use ModuleName qw(Functions...);`
> to your perl scripts.  
> 'ModuleName' and 'Functions' are set according to your needs.

**For Python Modules**

> Add `import sys`, `sys.path.insert(0,'/path/to/usefullib/python/')` and
> `from ModuleName import Class/Function` or `import ModuleName` to your python
> scripts.  
> 'ModuleName' and 'Class/Function' are set according to your needs.

## File Structure

* [perl](https://github.com/kepbod/usefullib/tree/master/perl) - perl modules
* [python](https://github.com/kepbod/usefullib/tree/master/python) - python modules
* [test](https://github.com/kepbod/usefullib/tree/master/test) - some script examples using these modules

## Modules

* [Overlap.pm](https://github.com/kepbod/usefullib/blob/master/perl/Overlap.pm): Deal with genomic intervals (like exons, introns...)  
    Functions: OverlapMax, OverlapMap, OverlapMerge
* [RefFileParse.pm](https://github.com/kepbod/usefullib/blob/master/perl/RefFileParse.pm): Parse reference files  
    Functions: ExtractInfo
* [SAMParse.pm](https://github.com/kepbod/usefullib/blob/master/perl/SAMParse.pm): Parse SAM files (mainly convert reads/junctions to bases)  
    Functions: ReadSplit
* [interval.py](https://github.com/kepbod/usefullib/blob/master/python/interval.py): Deal with genomic intervals (like exons, introns...)  
    Class: Interval
* [map.py](https://github.com/kepbod/usefullib/blob/master/python/map.py): Deal with mapping issues  
    Functions: mapto, overlapwith

## License

Copyright (c) 2013-2014 Xiao-Ou Zhang. See the LICENSE file for license rights and limitations (MIT).
