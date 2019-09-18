# G-code Snippets, Config and Scripts for Using PrusaSlicer (Slic3r) with the Flashforge Creator Pro

[See my website](https://www.dr-lex.be/software/ffcp-slic3r-profiles.html#config) for main instructions on installing and using these files.

This repository contains three things:

## G-code snippets
To be used in combination with my PrusaSlicer profiles as can be found on Thingiverse ([Thing:2367215](https://www.thingiverse.com/thing:2367215)). These snippets are also published separately in [Thing:2367350](https://www.thingiverse.com/thing:2367350) for convenience. Look on those Thing pages for instructions.

## PrusaSlicer config bundles
The actual configuration bundles that can be imported into PrusaSlicer. Given that it is somewhat cumbersome to update the G-code snippets embedded inside these configs, it is possible they will not always be in sync with the latest commits to the actual snippets. In that case you should paste the snippets into the PrusaSlicer printer profiles to update them.

These configs and G-code are made specifically for PrusaSlicer. They might work in the original Slic3r from which PrusaSlicer was forked, but I give no guarantees.

## The *make_fcp_x3g* script
This script can be configured as a post-processing script in PrusaSlicer to run specific post-processing scripts and finally generate an X3G file by invoking [GPX](https://github.com/markwal/GPX).

This is a Bash script that will work in Linux and Mac OS X. It can also be used with the WSL Linux environment in recent versions of **Windows.** To do this: create a BAT file, named for instance `slic3r_postprocess.bat`, that contains the following:
```
set fpath=%~1
set fpath=%fpath:'='"'"'%
bash /your/linux/path/to/make_fcp_x3g -w '%fpath%'
```
Replace “`/your/linux/path/to`” with the path to the actual location inside the Linux environment where you placed the *make_fcp_x3g* script (and make sure it is executable). Finally in PrusaSlicer, configure the Windows path to the .BAT file in all your *Print Settings* → *Output options* → *Post-processing scripts*.\
For instance if your Windows account name is *Foobar* and you named the file `slic3r_postprocess.bat` and placed it in your documents folder, then the path in PrusaSlicer should be: “`C:\Users\Foobar\Documents\slic3r_postprocess.bat`”.

For this to work, inside your WSL environment you must have a command `wslpath` that converts Windows paths to their Linux equivalent. This is automatically the case if you have Windows 10 version 1803 or newer with a standard WSL image. If not, follow the instructions in the file `poor_mans_wslpath.txt``.

As a fallback for those Windows users who cannot use WSL, there is an alternative BAT script `simple_ffcp_postproc.bat` that can be used as post-processing script. It performs the two most essential functions of the `make_fcp_x3g` script, namely the tool temperature workaround and invoking GPX. It requires Perl to be installed, instructions are inside the file. This is only the bare minimum to use PrusaSlicer with the FFCP, it is much recommended to use the Bash script instead if you can.


## License
These files are released under a Creative Commons Attribution 4.0 International license.
