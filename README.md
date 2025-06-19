# ReverseFirTree
[![PSScriptAnalyzer](https://github.com/sukibaby/ReverseFirTree/actions/workflows/powershell.yml/badge.svg?branch=master)](https://github.com/sukibaby/ReverseFirTree/actions/workflows/powershell.yml)

I didn't find any tool to easily format a list of variables as reverse fir tree (a.k.a. reverse christmas tree, reverse XMAS tree), so I threw together a little PowerShell script. :-)

Running this script on a text file named `input.txt` with the following contents:
```
int 	samplebits = 16;
unsigned int	last_cursor_pos = 0;
int	preferred_writeahead = 8192;
WAVEHDR	pcm = nullptr;
bool bInit = false;
array1 = {};
int32_t	    sample_rate_thing_  =   44100;
float   myCooolFloat  = 16;
array2 ={} ;
```

will provide a nicely formatted output file `input_formatted.txt` with the following contents:
```
int32_t sample_rate_thing_ = 44100;
unsigned int last_cursor_pos = 0;
int preferred_writeahead = 8192;
float myCooolFloat = 16;
WAVEHDR pcm = nullptr;
int samplebits = 16;
bool bInit = false;
array1 = {};
array2 = {};
```

It is capable of tie-breaking for commonly known C++ datatypes, and falls back on alphabetical sorting.

It uses PowerShell features which were introdued in PowerShell 3.0, so it should run as-is on the PowerShell that ships with Windows 8 and higher. Windows 7 users may need to upgrade first though.

Reverse fir tree styling is not very well documented, but is recommended in Kernel Maintainers [KVM 5.4.2 "Coding Style"](https://docs.kernel.org/process/maintainer-kvm-x86.html). Please feel free to suggest ways the sorting could be improved!
