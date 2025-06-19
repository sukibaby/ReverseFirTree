I didn't find any tool to easily format a list of variables as reverse fir tree (a.k.a. reverse christmas tree, reverse XMAS tree), so I threw together a little PowerShell script. :-)

Running this script on a text file named `input.txt` with the following contents:
```
int	samplerate = 44100;
int 	samplebits = 16;
unsigned int	last_cursor_pos = 0;
int	preferred_writeahead = 8192;
int64_t	preferred_chunksize = 1024;
WAVEHDR	pcm = nullptr;
bool bInit = false;
array1 = {};
```

will provide a nicely formatted output file `input_formatted.txt` with the following contents:
```
int64_t preferred_chunksize = 1024;
unsigned int last_cursor_pos = 0;
int preferred_writeahead = 8192;
int samplerate = 44100;
WAVEHDR pcm = nullptr;
int samplebits = 16;
bool bInit = false;
array1 = {};
```

It features tie-breaking for commonly known C++ datatypes.

It uses PowerShell features which were introdued in PowerShell 3.0, so it should run as-is on the PowerShell that ships with Windows 8 and higher. Windows 7 users may need to upgrade first though.

Reverse fir tree styling is not very well documented, but is recommended in Kernel Maintainers [KVM 5.4.2 "Coding Style"](https://docs.kernel.org/process/maintainer-kvm-x86.html).
